-- Allows a trusted server process to create a user inside an existing company.
-- raw_app_meta_data is writable only through the Supabase Auth admin API.

BEGIN;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user_row(
  auth_user_id uuid,
  auth_email text,
  auth_metadata jsonb,
  auth_app_metadata jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  new_company_id text;
  requested_company_id text;
  requested_role_id text;
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.users WHERE user_id = auth_user_id::text
  ) THEN
    RETURN;
  END IF;

  requested_company_id := NULLIF(
    TRIM(auth_app_metadata ->> 'smart_finance_company_id'),
    ''
  );
  requested_role_id := NULLIF(
    TRIM(auth_app_metadata ->> 'smart_finance_role_id'),
    ''
  );

  IF requested_company_id IS NOT NULL
     AND requested_role_id IN ('role_manager', 'role_accountant')
     AND EXISTS (
       SELECT 1
       FROM public.companies
       WHERE company_id = requested_company_id
     ) THEN
    INSERT INTO public.users (
      user_id, company_id, role_id, full_name, email, status
    )
    VALUES (
      auth_user_id::text,
      requested_company_id,
      requested_role_id,
      COALESCE(
        NULLIF(TRIM(auth_metadata ->> 'full_name'), ''),
        COALESCE(auth_email, 'Nhân viên mới')
      ),
      COALESCE(auth_email, auth_user_id::text || '@pending.local'),
      'ACTIVE'
    );
    RETURN;
  END IF;

  INSERT INTO public.companies (company_name)
  VALUES (
    COALESCE(
      NULLIF(TRIM(auth_metadata ->> 'business_name'), ''),
      'Doanh nghiệp của ' || COALESCE(auth_email, auth_user_id::text)
    )
  )
  RETURNING company_id INTO new_company_id;

  INSERT INTO public.users (
    user_id, company_id, role_id, full_name, email, status
  )
  VALUES (
    auth_user_id::text,
    new_company_id,
    'role_manager',
    COALESCE(
      NULLIF(TRIM(auth_metadata ->> 'full_name'), ''),
      COALESCE(auth_email, 'Người dùng mới')
    ),
    COALESCE(auth_email, auth_user_id::text || '@pending.local'),
    'ACTIVE'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_auth_user_row(
  uuid,
  text,
  jsonb,
  jsonb
) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM public.handle_new_auth_user_row(
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data,
    NEW.raw_app_meta_data
  );
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

COMMIT;

NOTIFY pgrst, 'reload schema';
