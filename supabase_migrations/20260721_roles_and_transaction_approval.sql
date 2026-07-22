-- SmartFinance role and transaction approval migration.
-- Safe to run repeatedly in the Supabase SQL Editor.

BEGIN;

INSERT INTO public.roles (role_id, role_name, description)
VALUES
  ('role_manager', 'MANAGER', 'Quản lý'),
  ('role_accountant', 'ACCOUNTANT', 'Nhân viên kế toán')
ON CONFLICT (role_id) DO UPDATE SET
  role_name = EXCLUDED.role_name,
  description = EXCLUDED.description;

UPDATE public.users
SET role_id = CASE
  WHEN role_id IN ('role_manager', 'role_01', 'role_02', 'role_09')
    THEN 'role_manager'
  ELSE 'role_accountant'
END;

DELETE FROM public.roles
WHERE role_id NOT IN ('role_manager', 'role_accountant');

-- Every self-registered business owner starts as MANAGER. Accountants are
-- profiles that a manager assigns to the same company afterwards.
CREATE OR REPLACE FUNCTION public.handle_new_auth_user_row(
  auth_user_id uuid,
  auth_email text,
  auth_metadata jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  new_company_id text;
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.users WHERE user_id = auth_user_id::text
  ) THEN
    RETURN;
  END IF;

  INSERT INTO public.companies (company_name)
  VALUES (
    COALESCE(
      NULLIF(TRIM(auth_metadata ->> 'business_name'), ''),
      'SmartFinance business ' || COALESCE(auth_email, auth_user_id::text)
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
      COALESCE(auth_email, 'New user')
    ),
    COALESCE(auth_email, auth_user_id::text || '@pending.local'),
    'ACTIVE'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_auth_user_row(uuid, text, jsonb)
FROM PUBLIC;

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
    NEW.raw_user_meta_data
  );
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS created_by TEXT;

UPDATE public.invoices
SET created_by = uploaded_by
WHERE created_by IS NULL;

ALTER TABLE public.invoices
  DROP CONSTRAINT IF EXISTS invoices_created_by_fkey;
ALTER TABLE public.invoices
  ADD CONSTRAINT invoices_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS approval_status TEXT,
  ADD COLUMN IF NOT EXISTS approved_by TEXT,
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

UPDATE public.transactions
SET approval_status = CASE UPPER(COALESCE(approval_status, ''))
  WHEN 'PENDING' THEN 'PENDING'
  WHEN 'REJECTED' THEN 'REJECTED'
  ELSE 'APPROVED'
END;

ALTER TABLE public.transactions
  ALTER COLUMN approval_status SET DEFAULT 'PENDING',
  ALTER COLUMN approval_status SET NOT NULL;

ALTER TABLE public.transactions
  DROP CONSTRAINT IF EXISTS transactions_approval_status_check;
ALTER TABLE public.transactions
  ADD CONSTRAINT transactions_approval_status_check
  CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED'));

ALTER TABLE public.transactions
  DROP CONSTRAINT IF EXISTS transactions_approved_by_fkey;
ALTER TABLE public.transactions
  ADD CONSTRAINT transactions_approved_by_fkey
  FOREIGN KEY (approved_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS transactions_company_approval_idx
ON public.transactions(company_id, approval_status, transaction_date DESC)
WHERE status = 'ACTIVE';

CREATE OR REPLACE FUNCTION public.current_role_name()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT UPPER(r.role_name)
  FROM public.users u
  JOIN public.roles r ON r.role_id = u.role_id
  WHERE u.user_id = auth.uid()::text
    AND u.status = 'ACTIVE'
  LIMIT 1
$$;

REVOKE ALL ON FUNCTION public.current_role_name() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_role_name() TO authenticated;

CREATE OR REPLACE FUNCTION public.protect_user_access_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.role_id IS DISTINCT FROM OLD.role_id
     OR NEW.status IS DISTINCT FROM OLD.status
     OR NEW.company_id IS DISTINCT FROM OLD.company_id THEN
    IF public.current_role_name() <> 'MANAGER' THEN
      RAISE EXCEPTION 'Only managers can change role, status or company';
    END IF;
    IF OLD.user_id = auth.uid()::text THEN
      RAISE EXCEPTION 'Managers cannot change their own access';
    END IF;
    IF OLD.company_id <> public.current_company_id()
       OR NEW.company_id <> public.current_company_id() THEN
      RAISE EXCEPTION 'Account must belong to the current company';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_user_access_fields ON public.users;
CREATE TRIGGER protect_user_access_fields
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.protect_user_access_fields();

DROP POLICY IF EXISTS "Users view own profile" ON public.users;
DROP POLICY IF EXISTS "Users update own profile" ON public.users;
DROP POLICY IF EXISTS "Managers view company users" ON public.users;
DROP POLICY IF EXISTS "Managers update company users" ON public.users;

CREATE POLICY "Users view own profile" ON public.users
FOR SELECT TO authenticated
USING (user_id = auth.uid()::text);

CREATE POLICY "Managers view company users" ON public.users
FOR SELECT TO authenticated
USING (
  public.current_role_name() = 'MANAGER'
  AND company_id = public.current_company_id()
);

CREATE POLICY "Users update own profile" ON public.users
FOR UPDATE TO authenticated
USING (user_id = auth.uid()::text)
WITH CHECK (
  user_id = auth.uid()::text
  AND company_id = public.current_company_id()
);

CREATE POLICY "Managers update company users" ON public.users
FOR UPDATE TO authenticated
USING (
  public.current_role_name() = 'MANAGER'
  AND company_id = public.current_company_id()
)
WITH CHECK (company_id = public.current_company_id());

DROP POLICY IF EXISTS "Company members manage invoices" ON public.invoices;
DROP POLICY IF EXISTS "Accountants manage own invoices" ON public.invoices;
DROP POLICY IF EXISTS "Managers view company invoices" ON public.invoices;

CREATE POLICY "Accountants manage own invoices" ON public.invoices
FOR ALL TO authenticated
USING (
  company_id = public.current_company_id()
  AND created_by = auth.uid()::text
)
WITH CHECK (
  public.current_role_name() = 'ACCOUNTANT'
  AND company_id = public.current_company_id()
  AND created_by = auth.uid()::text
);

CREATE POLICY "Managers view company invoices" ON public.invoices
FOR SELECT TO authenticated
USING (
  public.current_role_name() = 'MANAGER'
  AND company_id = public.current_company_id()
);

DROP POLICY IF EXISTS "Company members manage transactions" ON public.transactions;
DROP POLICY IF EXISTS "Accountants manage own pending transactions" ON public.transactions;
DROP POLICY IF EXISTS "Accountants view own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Accountants create own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Accountants update own pending transactions" ON public.transactions;
DROP POLICY IF EXISTS "Managers review company transactions" ON public.transactions;

CREATE POLICY "Accountants view own transactions" ON public.transactions
FOR SELECT TO authenticated
USING (
  public.current_role_name() = 'ACCOUNTANT'
  AND company_id = public.current_company_id()
  AND created_by = auth.uid()::text
);

CREATE POLICY "Accountants create own transactions" ON public.transactions
FOR INSERT TO authenticated
WITH CHECK (
  public.current_role_name() = 'ACCOUNTANT'
  AND company_id = public.current_company_id()
  AND created_by = auth.uid()::text
  AND approval_status = 'PENDING'
  AND approved_by IS NULL
  AND approved_at IS NULL
);

CREATE POLICY "Accountants update own pending transactions" ON public.transactions
FOR UPDATE TO authenticated
USING (
  public.current_role_name() = 'ACCOUNTANT'
  AND approval_status = 'PENDING'
  AND company_id = public.current_company_id()
  AND created_by = auth.uid()::text
)
WITH CHECK (
  public.current_role_name() = 'ACCOUNTANT'
  AND company_id = public.current_company_id()
  AND created_by = auth.uid()::text
  AND approval_status = 'PENDING'
  AND approved_by IS NULL
  AND approved_at IS NULL
);

CREATE POLICY "Managers review company transactions" ON public.transactions
FOR ALL TO authenticated
USING (
  public.current_role_name() = 'MANAGER'
  AND company_id = public.current_company_id()
)
WITH CHECK (
  public.current_role_name() = 'MANAGER'
  AND company_id = public.current_company_id()
);

COMMIT;

NOTIFY pgrst, 'reload schema';
