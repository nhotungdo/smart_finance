import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonResponse = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "Phương thức không được hỗ trợ." });
  }

  const authorization = request.headers.get("Authorization");
  const accessToken = authorization?.replace(/^Bearer\s+/i, "").trim();
  if (!accessToken) {
    return jsonResponse(401, { error: "Phiên đăng nhập không hợp lệ." });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse(500, { error: "Edge Function chưa được cấu hình." });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  const {
    data: { user: managerUser },
    error: authError,
  } = await admin.auth.getUser(accessToken);
  if (authError || !managerUser) {
    return jsonResponse(401, { error: "Phiên đăng nhập đã hết hạn." });
  }

  const { data: managerProfile, error: profileError } = await admin
    .from("users")
    .select("company_id, role_id, status")
    .eq("user_id", managerUser.id)
    .maybeSingle();
  if (profileError || !managerProfile) {
    return jsonResponse(403, { error: "Không tìm thấy hồ sơ quản lý." });
  }
  if (
    managerProfile.role_id !== "role_manager" ||
    managerProfile.status !== "ACTIVE" ||
    !managerProfile.company_id
  ) {
    return jsonResponse(403, {
      error: "Chỉ quản lý đang hoạt động mới được tạo tài khoản.",
    });
  }

  let payload: Record<string, unknown>;
  try {
    payload = await request.json();
  } catch (_) {
    return jsonResponse(400, { error: "Dữ liệu gửi lên không hợp lệ." });
  }

  const fullName = String(payload.full_name ?? "").trim();
  const email = String(payload.email ?? "").trim().toLowerCase();
  const password = String(payload.password ?? "");
  const roleId = String(payload.role_id ?? "role_accountant");
  const allowedRoles = new Set(["role_manager", "role_accountant"]);

  if (fullName.length < 2) {
    return jsonResponse(400, { error: "Họ và tên phải có ít nhất 2 ký tự." });
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return jsonResponse(400, { error: "Email không đúng định dạng." });
  }
  if (password.length < 6) {
    return jsonResponse(400, { error: "Mật khẩu phải có ít nhất 6 ký tự." });
  }
  if (!allowedRoles.has(roleId)) {
    return jsonResponse(400, { error: "Vai trò tài khoản không hợp lệ." });
  }

  const { data: existingProfile } = await admin
    .from("users")
    .select("user_id")
    .eq("email", email)
    .maybeSingle();
  if (existingProfile) {
    return jsonResponse(409, { error: "Email này đã có tài khoản." });
  }

  const { data: created, error: createError } =
    await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: fullName },
      app_metadata: {
        smart_finance_company_id: managerProfile.company_id,
        smart_finance_role_id: roleId,
        smart_finance_created_by: managerUser.id,
      },
    });

  if (createError || !created.user) {
    const duplicate = createError?.message
      .toLowerCase()
      .includes("already been registered");
    return jsonResponse(duplicate ? 409 : 400, {
      error: duplicate
        ? "Email này đã tồn tại trong Supabase Authentication."
        : "Không thể tạo tài khoản đăng nhập.",
    });
  }

  const accountPayload = {
    user_id: created.user.id,
    company_id: managerProfile.company_id,
    role_id: roleId,
    full_name: fullName,
    email,
    password_hash: null,
    status: "ACTIVE",
    updated_at: new Date().toISOString(),
    is_synced: 1,
  };
  const { data: account, error: accountError } = await admin
    .from("users")
    .upsert(accountPayload, { onConflict: "user_id" })
    .select()
    .single();

  if (accountError || !account) {
    await admin.from("users").delete().eq("user_id", created.user.id);
    await admin.auth.admin.deleteUser(created.user.id);
    return jsonResponse(500, {
      error: "Đã tạo Auth user nhưng không thể tạo hồ sơ nhân viên.",
    });
  }

  return jsonResponse(201, { account });
});
