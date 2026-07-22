-- Supabase Schema for SmartFinance
-- Execute this in the Supabase SQL Editor

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. COMPANIES
CREATE TABLE IF NOT EXISTS public.companies (
  company_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  company_name TEXT NOT NULL,
  tax_code TEXT,
  address TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  is_synced SMALLINT DEFAULT 1
);

-- 2. ROLES
CREATE TABLE IF NOT EXISTS public.roles (
  role_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  role_name TEXT NOT NULL UNIQUE,
  description TEXT,
  is_synced SMALLINT DEFAULT 1
);

-- 3. USERS
CREATE TABLE IF NOT EXISTS public.users (
  user_id TEXT PRIMARY KEY,
  company_id TEXT REFERENCES public.companies(company_id) ON DELETE CASCADE,
  role_id TEXT REFERENCES public.roles(role_id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT,
  phone TEXT,
  status TEXT NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE', 'DELETED')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  is_synced SMALLINT DEFAULT 1
);

-- 4. CATEGORIES
CREATE TABLE IF NOT EXISTS public.categories (
  category_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  company_id TEXT REFERENCES public.companies(company_id) ON DELETE CASCADE,
  category_name TEXT NOT NULL,
  category_type TEXT NOT NULL
    CHECK (category_type IN ('INCOME', 'EXPENSE')),
  icon_name TEXT,
  color_code TEXT,
  is_default SMALLINT DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE', 'DELETED')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  is_synced SMALLINT DEFAULT 1
);

-- 5. INVOICES
CREATE TABLE IF NOT EXISTS public.invoices (
  invoice_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  company_id TEXT REFERENCES public.companies(company_id) ON DELETE CASCADE,
  uploaded_by TEXT REFERENCES public.users(user_id) ON DELETE SET NULL,
  created_by TEXT REFERENCES public.users(user_id) ON DELETE SET NULL,
  invoice_type TEXT NOT NULL DEFAULT 'EXPENSE'
    CHECK (invoice_type IN ('INCOME', 'EXPENSE')),
  supplier_name TEXT,
  supplier_tax_code TEXT,
  invoice_number TEXT,
  invoice_date TIMESTAMP WITH TIME ZONE,
  subtotal INTEGER,
  vat_rate INTEGER,
  vat_amount INTEGER,
  total_amount INTEGER,
  image_path TEXT,
  scan_status TEXT NOT NULL DEFAULT 'NOT_SCANNED'
    CHECK (scan_status IN ('NOT_SCANNED', 'SCANNING', 'SCANNED', 'ERROR')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  is_synced SMALLINT DEFAULT 1
);

-- 6. TRANSACTIONS
CREATE TABLE IF NOT EXISTS public.transactions (
  transaction_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  company_id TEXT REFERENCES public.companies(company_id) ON DELETE CASCADE,
  category_id TEXT REFERENCES public.categories(category_id) ON DELETE SET NULL,
  created_by TEXT REFERENCES public.users(user_id) ON DELETE SET NULL,
  invoice_id TEXT REFERENCES public.invoices(invoice_id) ON DELETE SET NULL,
  amount INTEGER NOT NULL,
  transaction_type TEXT NOT NULL
    CHECK (transaction_type IN ('INCOME', 'EXPENSE')),
  transaction_date TIMESTAMP WITH TIME ZONE NOT NULL,
  description TEXT,
  receipt_image_path TEXT,
  status TEXT NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE', 'DELETED')),
  approval_status TEXT NOT NULL DEFAULT 'PENDING'
    CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED')),
  approved_by TEXT REFERENCES public.users(user_id) ON DELETE SET NULL,
  approved_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  is_synced SMALLINT DEFAULT 1
);

-- 7. OCR_RESULTS
CREATE TABLE IF NOT EXISTS public.ocr_results (
  ocr_result_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  invoice_id TEXT REFERENCES public.invoices(invoice_id) ON DELETE CASCADE,
  extracted_supplier_name TEXT,
  extracted_tax_code TEXT,
  extracted_amount INTEGER,
  raw_mock_data TEXT,
  status TEXT NOT NULL DEFAULT 'SCANNED'
    CHECK (status IN ('NOT_SCANNED', 'SCANNING', 'SCANNED', 'ERROR')),
  scanned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. PDF_EXPORTS
CREATE TABLE IF NOT EXISTS public.pdf_exports (
  pdf_export_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  company_id TEXT REFERENCES public.companies(company_id) ON DELETE CASCADE,
  exported_by TEXT REFERENCES public.users(user_id) ON DELETE SET NULL,
  invoice_id TEXT REFERENCES public.invoices(invoice_id) ON DELETE SET NULL,
  export_type TEXT NOT NULL,
  file_path TEXT NOT NULL,
  exported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_synced SMALLINT DEFAULT 1
);

-- Apply these defaults to existing tables too.
-- CREATE TABLE IF NOT EXISTS will not update columns that already exist.
ALTER TABLE public.companies
  ALTER COLUMN company_id SET DEFAULT gen_random_uuid()::text;

ALTER TABLE public.roles
  ALTER COLUMN role_id SET DEFAULT gen_random_uuid()::text;

ALTER TABLE public.categories
  ALTER COLUMN category_id SET DEFAULT gen_random_uuid()::text;

ALTER TABLE public.invoices
  ALTER COLUMN invoice_id SET DEFAULT gen_random_uuid()::text;

ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS invoice_type TEXT;

ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS created_by TEXT;

UPDATE public.invoices SET created_by = uploaded_by WHERE created_by IS NULL;

ALTER TABLE public.transactions
  ALTER COLUMN transaction_id SET DEFAULT gen_random_uuid()::text;

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

ALTER TABLE public.ocr_results
  ALTER COLUMN ocr_result_id SET DEFAULT gen_random_uuid()::text;

ALTER TABLE public.pdf_exports
  ALTER COLUMN pdf_export_id SET DEFAULT gen_random_uuid()::text;

-- Money values are stored as integer VND to avoid floating point rounding.
ALTER TABLE public.transactions
  ALTER COLUMN amount TYPE INTEGER USING ROUND(amount)::integer;

ALTER TABLE public.invoices
  ALTER COLUMN subtotal TYPE INTEGER USING ROUND(subtotal)::integer,
  ALTER COLUMN vat_rate TYPE INTEGER USING ROUND(vat_rate)::integer,
  ALTER COLUMN vat_amount TYPE INTEGER USING ROUND(vat_amount)::integer,
  ALTER COLUMN total_amount TYPE INTEGER USING ROUND(total_amount)::integer;

ALTER TABLE public.ocr_results
  ALTER COLUMN extracted_amount TYPE INTEGER USING ROUND(extracted_amount)::integer;

-- Normalize legacy enum values before enforcing the assignment constraints.
UPDATE public.users
SET status = CASE WHEN UPPER(status) = 'DELETED' THEN 'DELETED' ELSE 'ACTIVE' END;

UPDATE public.categories
SET category_type = UPPER(category_type),
    status = CASE WHEN UPPER(status) = 'DELETED' THEN 'DELETED' ELSE 'ACTIVE' END;

UPDATE public.transactions
SET transaction_type = UPPER(transaction_type),
    status = CASE WHEN UPPER(status) = 'DELETED' THEN 'DELETED' ELSE 'ACTIVE' END;

UPDATE public.invoices
SET scan_status = CASE UPPER(scan_status)
  WHEN 'SCANNING' THEN 'SCANNING'
  WHEN 'SCANNED' THEN 'SCANNED'
  WHEN 'PROCESSED' THEN 'SCANNED'
  WHEN 'COMPLETED' THEN 'SCANNED'
  WHEN 'MANUAL' THEN 'SCANNED'
  WHEN 'ERROR' THEN 'ERROR'
  WHEN 'FAILED' THEN 'ERROR'
  ELSE 'NOT_SCANNED'
END;

UPDATE public.ocr_results
SET status = CASE
  WHEN UPPER(status) IN ('ERROR', 'FAILED') THEN 'ERROR'
  ELSE 'SCANNED'
END;

UPDATE public.invoices
SET vat_rate = 10,
    vat_amount = CASE
      WHEN subtotal IS NULL THEN NULL
      ELSE ROUND(subtotal * 10.0 / 100)::integer
    END,
    total_amount = CASE
      WHEN subtotal IS NULL THEN total_amount
      ELSE subtotal + ROUND(subtotal * 10.0 / 100)::integer
    END
WHERE vat_rate IS NOT NULL AND vat_rate NOT IN (8, 10);

UPDATE public.invoices
SET invoice_type = CASE
  WHEN UPPER(COALESCE(invoice_type, '')) = 'INCOME' THEN 'INCOME'
  ELSE 'EXPENSE'
END;

-- Supabase Auth owns credentials; public.users must never keep passwords.
UPDATE public.users SET password_hash = NULL WHERE password_hash IS NOT NULL;

ALTER TABLE public.users ALTER COLUMN status SET DEFAULT 'ACTIVE';
ALTER TABLE public.categories ALTER COLUMN status SET DEFAULT 'ACTIVE';
ALTER TABLE public.invoices ALTER COLUMN scan_status SET DEFAULT 'NOT_SCANNED';
ALTER TABLE public.invoices
  ALTER COLUMN invoice_type SET DEFAULT 'EXPENSE',
  ALTER COLUMN invoice_type SET NOT NULL;
ALTER TABLE public.transactions ALTER COLUMN status SET DEFAULT 'ACTIVE';
ALTER TABLE public.ocr_results ALTER COLUMN status SET DEFAULT 'SCANNED';

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_status_check;
ALTER TABLE public.users ADD CONSTRAINT users_status_check
  CHECK (status IN ('ACTIVE', 'DELETED'));
ALTER TABLE public.categories DROP CONSTRAINT IF EXISTS categories_category_type_check;
ALTER TABLE public.categories ADD CONSTRAINT categories_category_type_check
  CHECK (category_type IN ('INCOME', 'EXPENSE'));
ALTER TABLE public.categories DROP CONSTRAINT IF EXISTS categories_status_check;
ALTER TABLE public.categories ADD CONSTRAINT categories_status_check
  CHECK (status IN ('ACTIVE', 'DELETED'));
ALTER TABLE public.invoices DROP CONSTRAINT IF EXISTS invoices_scan_status_check;
ALTER TABLE public.invoices ADD CONSTRAINT invoices_scan_status_check
  CHECK (scan_status IN ('NOT_SCANNED', 'SCANNING', 'SCANNED', 'ERROR'));
ALTER TABLE public.invoices DROP CONSTRAINT IF EXISTS invoices_vat_rate_check;
ALTER TABLE public.invoices ADD CONSTRAINT invoices_vat_rate_check
  CHECK (vat_rate IS NULL OR vat_rate IN (8, 10));
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_transaction_type_check;
ALTER TABLE public.transactions ADD CONSTRAINT transactions_transaction_type_check
  CHECK (transaction_type IN ('INCOME', 'EXPENSE'));
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_status_check;
ALTER TABLE public.transactions ADD CONSTRAINT transactions_status_check
  CHECK (status IN ('ACTIVE', 'DELETED'));
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_approval_status_check;
ALTER TABLE public.transactions ADD CONSTRAINT transactions_approval_status_check
  CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED'));
ALTER TABLE public.invoices DROP CONSTRAINT IF EXISTS invoices_created_by_fkey;
ALTER TABLE public.invoices ADD CONSTRAINT invoices_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_approved_by_fkey;
ALTER TABLE public.transactions ADD CONSTRAINT transactions_approved_by_fkey
  FOREIGN KEY (approved_by) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.invoices DROP CONSTRAINT IF EXISTS invoices_invoice_type_check;
ALTER TABLE public.invoices ADD CONSTRAINT invoices_invoice_type_check
  CHECK (invoice_type IN ('INCOME', 'EXPENSE'));
ALTER TABLE public.ocr_results DROP CONSTRAINT IF EXISTS ocr_results_status_check;
ALTER TABLE public.ocr_results ADD CONSTRAINT ocr_results_status_check
  CHECK (status IN ('NOT_SCANNED', 'SCANNING', 'SCANNED', 'ERROR'));

CREATE UNIQUE INDEX IF NOT EXISTS transactions_one_active_invoice_idx
ON public.transactions(invoice_id)
WHERE invoice_id IS NOT NULL AND status = 'ACTIVE';

CREATE INDEX IF NOT EXISTS transactions_company_approval_idx
ON public.transactions(company_id, approval_status, transaction_date DESC)
WHERE status = 'ACTIVE';

-- Merge legacy duplicate categories before enforcing semantic uniqueness.
WITH ranked_categories AS (
  SELECT
    category_id,
    FIRST_VALUE(category_id) OVER (
      PARTITION BY
        COALESCE(company_id, ''),
        LOWER(BTRIM(category_name)),
        category_type
      ORDER BY created_at NULLS LAST, category_id
    ) AS canonical_id
  FROM public.categories
  WHERE status = 'ACTIVE'
)
UPDATE public.transactions AS tx
SET category_id = ranked.canonical_id
FROM ranked_categories AS ranked
WHERE tx.category_id = ranked.category_id
  AND ranked.category_id <> ranked.canonical_id;

WITH ranked_categories AS (
  SELECT
    category_id,
    FIRST_VALUE(category_id) OVER (
      PARTITION BY
        COALESCE(company_id, ''),
        LOWER(BTRIM(category_name)),
        category_type
      ORDER BY created_at NULLS LAST, category_id
    ) AS canonical_id
  FROM public.categories
  WHERE status = 'ACTIVE'
)
DELETE FROM public.categories AS category
USING ranked_categories AS ranked
WHERE category.category_id = ranked.category_id
  AND ranked.category_id <> ranked.canonical_id;

CREATE UNIQUE INDEX IF NOT EXISTS categories_company_name_type_active_idx
ON public.categories (
  COALESCE(company_id, ''),
  LOWER(BTRIM(category_name)),
  category_type
)
WHERE status = 'ACTIVE';

-- Create company/profile in the same database transaction as Supabase Auth.
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  new_company_id text;
  default_role_id text;
BEGIN
  IF EXISTS (SELECT 1 FROM public.users WHERE user_id = NEW.id::text) THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.companies (company_name)
  VALUES (
    COALESCE(
      NULLIF(TRIM(NEW.raw_user_meta_data ->> 'business_name'), ''),
      'Doanh nghiệp của ' || COALESCE(NEW.email, NEW.id::text)
    )
  )
  RETURNING company_id INTO new_company_id;

  SELECT role_id INTO default_role_id
  FROM public.roles
  WHERE role_id = 'role_manager'
  LIMIT 1;

  INSERT INTO public.users (
    user_id,
    company_id,
    role_id,
    full_name,
    email,
    status
  )
  VALUES (
    NEW.id::text,
    new_company_id,
    default_role_id,
    COALESCE(
      NULLIF(TRIM(NEW.raw_user_meta_data ->> 'full_name'), ''),
      COALESCE(NEW.email, 'Người dùng mới')
    ),
    COALESCE(NEW.email, NEW.id::text || '@pending.local'),
    'ACTIVE'
  );

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

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
  default_role_id text;
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
      'Doanh nghiệp của ' || COALESCE(auth_email, auth_user_id::text)
    )
  )
  RETURNING company_id INTO new_company_id;

  SELECT role_id INTO default_role_id
  FROM public.roles
  WHERE role_id = 'role_manager'
  LIMIT 1;

  INSERT INTO public.users (
    user_id, company_id, role_id, full_name, email, status
  )
  VALUES (
    auth_user_id::text,
    new_company_id,
    default_role_id,
    COALESCE(
      NULLIF(TRIM(auth_metadata ->> 'full_name'), ''),
      COALESCE(auth_email, 'Người dùng mới')
    ),
    COALESCE(auth_email, auth_user_id::text || '@pending.local'),
    'ACTIVE'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_auth_user_row(uuid, text, jsonb)
FROM PUBLIC;

-- Auth users created by the manager Edge Function join the manager's company.
-- The regular three-argument helper above remains the self-registration path.
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
       SELECT 1 FROM public.companies
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

-- Backfill helper for Auth users created before the trigger existed.
CREATE OR REPLACE FUNCTION public.ensure_user_profile()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  auth_user auth.users%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.users WHERE user_id = auth.uid()::text
  ) THEN
    RETURN;
  END IF;

  SELECT * INTO auth_user FROM auth.users WHERE id = auth.uid();
  PERFORM public.handle_new_auth_user_row(
    auth_user.id,
    auth_user.email,
    auth_user.raw_user_meta_data,
    auth_user.raw_app_meta_data
  );
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_user_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ensure_user_profile() TO authenticated;

CREATE OR REPLACE FUNCTION public.current_company_id()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT company_id
  FROM public.users
  WHERE user_id = auth.uid()::text
    AND status = 'ACTIVE'
  LIMIT 1
$$;

REVOKE ALL ON FUNCTION public.current_company_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_company_id() TO authenticated;

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
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  IF NEW.role_id IS DISTINCT FROM OLD.role_id
     OR NEW.status IS DISTINCT FROM OLD.status
     OR NEW.company_id IS DISTINCT FROM OLD.company_id THEN
    IF public.current_role_name() <> 'MANAGER' THEN
      RAISE EXCEPTION 'Only managers can change role, status or company';
    END IF;
    IF OLD.user_id = auth.uid()::text THEN
      RAISE EXCEPTION 'Managers cannot change their own access';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_user_access_fields ON public.users;
CREATE TRIGGER protect_user_access_fields
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.protect_user_access_fields();

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ocr_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pdf_exports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.companies;
DROP POLICY IF EXISTS "Enable select for authenticated users" ON public.companies;
DROP POLICY IF EXISTS "Enable update for users based on company_id" ON public.companies;
DROP POLICY IF EXISTS "Company members view company" ON public.companies;
DROP POLICY IF EXISTS "Company members update company" ON public.companies;
CREATE POLICY "Company members view company" ON public.companies
FOR SELECT TO authenticated
USING (company_id = public.current_company_id());
CREATE POLICY "Company members update company" ON public.companies
FOR UPDATE TO authenticated
USING (company_id = public.current_company_id())
WITH CHECK (company_id = public.current_company_id());

DROP POLICY IF EXISTS "Authenticated users view roles" ON public.roles;
CREATE POLICY "Authenticated users view roles" ON public.roles
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Enable insert for users based on user_id" ON public.users;
DROP POLICY IF EXISTS "Enable select for users based on user_id" ON public.users;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.users;
DROP POLICY IF EXISTS "Users view own profile" ON public.users;
DROP POLICY IF EXISTS "Users update own profile" ON public.users;
DROP POLICY IF EXISTS "Managers view company users" ON public.users;
DROP POLICY IF EXISTS "Managers update company users" ON public.users;
CREATE POLICY "Users view own profile" ON public.users
FOR SELECT TO authenticated USING (user_id = auth.uid()::text);
CREATE POLICY "Managers view company users" ON public.users
FOR SELECT TO authenticated USING (
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

DROP POLICY IF EXISTS "Company members manage categories" ON public.categories;
CREATE POLICY "Company members manage categories" ON public.categories
FOR ALL TO authenticated
USING (company_id = public.current_company_id())
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
FOR SELECT TO authenticated USING (
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

DROP POLICY IF EXISTS "Company members manage OCR results" ON public.ocr_results;
CREATE POLICY "Company members manage OCR results" ON public.ocr_results
FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.invoices i
    WHERE i.invoice_id = ocr_results.invoice_id
      AND i.company_id = public.current_company_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.invoices i
    WHERE i.invoice_id = ocr_results.invoice_id
      AND i.company_id = public.current_company_id()
  )
);

DROP POLICY IF EXISTS "Company members manage PDF exports" ON public.pdf_exports;
CREATE POLICY "Company members manage PDF exports" ON public.pdf_exports
FOR ALL TO authenticated
USING (company_id = public.current_company_id())
WITH CHECK (
  company_id = public.current_company_id()
  AND exported_by = auth.uid()::text
);

INSERT INTO storage.buckets (id, name, public)
VALUES ('invoices', 'invoices', false)
ON CONFLICT (id) DO UPDATE SET public = false;

DROP POLICY IF EXISTS "Company members view invoice images" ON storage.objects;
DROP POLICY IF EXISTS "Company members upload invoice images" ON storage.objects;
DROP POLICY IF EXISTS "Company members update invoice images" ON storage.objects;
DROP POLICY IF EXISTS "Company members delete invoice images" ON storage.objects;

CREATE POLICY "Company members view invoice images" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'invoices'
  AND (storage.foldername(name))[1] = public.current_company_id()
);

CREATE POLICY "Company members upload invoice images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'invoices'
  AND (storage.foldername(name))[1] = public.current_company_id()
);

CREATE POLICY "Company members update invoice images" ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'invoices'
  AND (storage.foldername(name))[1] = public.current_company_id()
)
WITH CHECK (
  bucket_id = 'invoices'
  AND (storage.foldername(name))[1] = public.current_company_id()
);

CREATE POLICY "Company members delete invoice images" ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'invoices'
  AND (storage.foldername(name))[1] = public.current_company_id()
);

-- =========================================================================
-- MOCK DATA (10 ROWS PER TABLE)
-- =========================================================================

-- 1. COMPANIES (10 records)
INSERT INTO public.companies (company_id, company_name, tax_code, address, phone) VALUES 
('comp_01', 'Công ty TNHH SmartFinance', '0101234567', 'Hà Nội', '0901234567'),
('comp_02', 'Công ty Cổ phần TechVN', '0102345678', 'Hồ Chí Minh', '0902345678'),
('comp_03', 'Công ty TNHH Dịch vụ ABC', '0103456789', 'Đà Nẵng', '0903456789'),
('comp_04', 'Tập đoàn Xây dựng XYZ', '0104567890', 'Hải Phòng', '0904567890'),
('comp_05', 'Công ty Thương mại Dịch vụ 123', '0105678901', 'Cần Thơ', '0905678901'),
('comp_06', 'Công ty TNHH Phần mềm Vina', '0106789012', 'Bình Dương', '0906789012'),
('comp_07', 'Công ty TNHH TM Tân Tiến', '0107890123', 'Đồng Nai', '0907890123'),
('comp_08', 'Công ty Cổ phần Đầu tư Thịnh Vượng', '0108901234', 'Quảng Ninh', '0908901234'),
('comp_09', 'Công ty TNHH Sản xuất Hưng Phát', '0109012345', 'Bắc Ninh', '0909012345'),
('comp_10', 'Công ty TNHH Dịch vụ Bảo vệ Toàn Cầu', '0100123456', 'Vũng Tàu', '0900123456')
ON CONFLICT DO NOTHING;

-- 2. ROLES
INSERT INTO public.roles (role_id, role_name, description) VALUES 
('role_manager', 'MANAGER', 'Quản lý'),
('role_accountant', 'ACCOUNTANT', 'Nhân viên kế toán')
ON CONFLICT DO NOTHING;

-- 3. USERS (10 records)
INSERT INTO public.users (user_id, company_id, role_id, full_name, email, phone) VALUES
('user_01', 'comp_01', 'role_manager', 'Nguyễn Văn A', 'nguyenvana@gmail.com', '0901111111'),
('user_02', 'comp_02', 'role_manager', 'Trần Thị B', 'tranthib@gmail.com', '0902222222'),
('user_03', 'comp_03', 'role_accountant', 'Lê Văn C', 'levanc@gmail.com', '0903333333'),
('user_04', 'comp_04', 'role_accountant', 'Phạm Thị D', 'phamthid@gmail.com', '0904444444'),
('user_05', 'comp_05', 'role_accountant', 'Hoàng Văn E', 'hoangvane@gmail.com', '0905555555'),
('user_06', 'comp_06', 'role_accountant', 'Đỗ Thị F', 'dothif@gmail.com', '0906666666'),
('user_07', 'comp_07', 'role_accountant', 'Ngô Văn G', 'ngovang@gmail.com', '0907777777'),
('user_08', 'comp_08', 'role_accountant', 'Vũ Thị H', 'vuthih@gmail.com', '0908888888'),
('user_09', 'comp_09', 'role_manager', 'Đặng Văn I', 'dangvani@gmail.com', '0909999999'),
('user_10', 'comp_10', 'role_accountant', 'Bùi Thị K', 'buithik@gmail.com', '0910000000')
ON CONFLICT DO NOTHING;

-- 4. CATEGORIES (10 records)
INSERT INTO public.categories (category_id, company_id, category_name, category_type, icon_name, color_code, is_default) VALUES 
('cat_01', 'comp_01', 'Tiền lương', 'EXPENSE', 'attach_money', '#FF5722', 1),
('cat_02', 'comp_01', 'Bán hàng', 'INCOME', 'store', '#4CAF50', 1),
('cat_03', 'comp_02', 'Văn phòng phẩm', 'EXPENSE', 'edit', '#2196F3', 0),
('cat_04', 'comp_02', 'Dịch vụ', 'INCOME', 'build', '#9C27B0', 0),
('cat_05', 'comp_03', 'Tiếp khách', 'EXPENSE', 'restaurant', '#FF9800', 0),
('cat_06', 'comp_03', 'Đầu tư', 'INCOME', 'trending_up', '#3F51B5', 0),
('cat_07', 'comp_04', 'Marketing', 'EXPENSE', 'campaign', '#E91E63', 0),
('cat_08', 'comp_04', 'Chiết khấu', 'INCOME', 'local_offer', '#009688', 0),
('cat_09', 'comp_05', 'Vận chuyển', 'EXPENSE', 'local_shipping', '#795548', 0),
('cat_10', 'comp_05', 'Hoàn thuế', 'INCOME', 'account_balance', '#607D8B', 0)
ON CONFLICT DO NOTHING;

-- 5. INVOICES (10 records)
INSERT INTO public.invoices (invoice_id, company_id, uploaded_by, created_by, supplier_name, supplier_tax_code, invoice_number, subtotal, vat_rate, vat_amount, total_amount, scan_status) VALUES
('inv_01', 'comp_01', 'user_01', 'user_01', 'Nhà cung cấp A', '0101111111', 'HD-001', 1000000, 10, 100000, 1100000, 'SCANNED'),
('inv_02', 'comp_02', 'user_02', 'user_02', 'Nhà cung cấp B', '0102222222', 'HD-002', 2000000, 10, 200000, 2200000, 'SCANNED'),
('inv_03', 'comp_03', 'user_03', 'user_03', 'Nhà cung cấp C', '0103333333', 'HD-003', 3000000, 8, 240000, 3240000, 'NOT_SCANNED'),
('inv_04', 'comp_04', 'user_04', 'user_04', 'Nhà cung cấp D', '0104444444', 'HD-004', 4000000, 10, 400000, 4400000, 'ERROR'),
('inv_05', 'comp_05', 'user_05', 'user_05', 'Nhà cung cấp E', '0105555555', 'HD-005', 5000000, 10, 500000, 5500000, 'SCANNED'),
('inv_06', 'comp_06', 'user_06', 'user_06', 'Nhà cung cấp F', '0106666666', 'HD-006', 6000000, 10, 600000, 6600000, 'SCANNED'),
('inv_07', 'comp_07', 'user_07', 'user_07', 'Nhà cung cấp G', '0107777777', 'HD-007', 7000000, 10, 700000, 7700000, 'NOT_SCANNED'),
('inv_08', 'comp_08', 'user_08', 'user_08', 'Nhà cung cấp H', '0108888888', 'HD-008', 8000000, 8, 640000, 8640000, 'SCANNED'),
('inv_09', 'comp_09', 'user_09', 'user_09', 'Nhà cung cấp I', '0109999999', 'HD-009', 9000000, 10, 900000, 9900000, 'SCANNED'),
('inv_10', 'comp_10', 'user_10', 'user_10', 'Nhà cung cấp K', '0100000000', 'HD-010', 10000000, 10, 1000000, 11000000, 'NOT_SCANNED')
ON CONFLICT DO NOTHING;

-- 6. TRANSACTIONS (10 records)
INSERT INTO public.transactions (transaction_id, company_id, category_id, created_by, invoice_id, amount, transaction_type, transaction_date, description, status, approval_status) VALUES
('trans_01', 'comp_01', 'cat_01', 'user_01', 'inv_01', 1100000, 'EXPENSE', NOW(), 'Thanh toán HD-001', 'ACTIVE', 'APPROVED'),
('trans_02', 'comp_02', 'cat_03', 'user_02', 'inv_02', 2200000, 'EXPENSE', NOW(), 'Thanh toán HD-002', 'ACTIVE', 'APPROVED'),
('trans_03', 'comp_03', 'cat_05', 'user_03', 'inv_03', 3240000, 'EXPENSE', NOW(), 'Thanh toán HD-003', 'ACTIVE', 'APPROVED'),
('trans_04', 'comp_04', 'cat_07', 'user_04', 'inv_04', 4400000, 'EXPENSE', NOW(), 'Thanh toán HD-004', 'ACTIVE', 'APPROVED'),
('trans_05', 'comp_05', 'cat_09', 'user_05', 'inv_05', 5500000, 'EXPENSE', NOW(), 'Thanh toán HD-005', 'ACTIVE', 'APPROVED'),
('trans_06', 'comp_01', 'cat_02', 'user_01', NULL, 15000000, 'INCOME', NOW(), 'Doanh thu bán hàng tháng 1', 'ACTIVE', 'APPROVED'),
('trans_07', 'comp_02', 'cat_04', 'user_02', NULL, 25000000, 'INCOME', NOW(), 'Doanh thu dịch vụ tháng 1', 'ACTIVE', 'APPROVED'),
('trans_08', 'comp_03', 'cat_06', 'user_03', NULL, 35000000, 'INCOME', NOW(), 'Lợi nhuận đầu tư', 'ACTIVE', 'APPROVED'),
('trans_09', 'comp_04', 'cat_08', 'user_04', NULL, 45000000, 'INCOME', NOW(), 'Chiết khấu bán hàng', 'ACTIVE', 'APPROVED'),
('trans_10', 'comp_05', 'cat_10', 'user_05', NULL, 55000000, 'INCOME', NOW(), 'Hoàn thuế GTGT', 'ACTIVE', 'APPROVED')
ON CONFLICT DO NOTHING;

-- 7. OCR_RESULTS (10 records)
INSERT INTO public.ocr_results (ocr_result_id, invoice_id, extracted_supplier_name, extracted_tax_code, extracted_amount, raw_mock_data, status) VALUES 
('ocr_01', 'inv_01', 'Nhà cung cấp A', '0101111111', 1100000, '{"data": "mock_1"}', 'SCANNED'),
('ocr_02', 'inv_02', 'Nhà cung cấp B', '0102222222', 2200000, '{"data": "mock_2"}', 'SCANNED'),
('ocr_03', 'inv_03', 'Nhà cung cấp C', '0103333333', 3240000, '{"data": "mock_3"}', 'SCANNED'),
('ocr_04', 'inv_04', 'Nhà cung cấp D', '0104444444', 4400000, '{"data": "mock_4"}', 'ERROR'),
('ocr_05', 'inv_05', 'Nhà cung cấp E', '0105555555', 5500000, '{"data": "mock_5"}', 'SCANNED'),
('ocr_06', 'inv_06', 'Nhà cung cấp F', '0106666666', 6600000, '{"data": "mock_6"}', 'SCANNED'),
('ocr_07', 'inv_07', 'Nhà cung cấp G', '0107777777', 7700000, '{"data": "mock_7"}', 'SCANNED'),
('ocr_08', 'inv_08', 'Nhà cung cấp H', '0108888888', 8640000, '{"data": "mock_8"}', 'SCANNED'),
('ocr_09', 'inv_09', 'Nhà cung cấp I', '0109999999', 9900000, '{"data": "mock_9"}', 'SCANNED'),
('ocr_10', 'inv_10', 'Nhà cung cấp K', '0100000000', 11000000, '{"data": "mock_10"}', 'SCANNED')
ON CONFLICT DO NOTHING;

-- 8. PDF_EXPORTS (10 records)
INSERT INTO public.pdf_exports (pdf_export_id, company_id, exported_by, invoice_id, export_type, file_path) VALUES 
('pdf_01', 'comp_01', 'user_01', 'inv_01', 'invoice', '/exports/pdf_01.pdf'),
('pdf_02', 'comp_02', 'user_02', 'inv_02', 'invoice', '/exports/pdf_02.pdf'),
('pdf_03', 'comp_03', 'user_03', 'inv_03', 'report', '/exports/pdf_03.pdf'),
('pdf_04', 'comp_04', 'user_04', 'inv_04', 'report', '/exports/pdf_04.pdf'),
('pdf_05', 'comp_05', 'user_05', 'inv_05', 'invoice', '/exports/pdf_05.pdf'),
('pdf_06', 'comp_06', 'user_06', 'inv_06', 'invoice', '/exports/pdf_06.pdf'),
('pdf_07', 'comp_07', 'user_07', 'inv_07', 'report', '/exports/pdf_07.pdf'),
('pdf_08', 'comp_08', 'user_08', 'inv_08', 'report', '/exports/pdf_08.pdf'),
('pdf_09', 'comp_09', 'user_09', 'inv_09', 'invoice', '/exports/pdf_09.pdf'),
('pdf_10', 'comp_10', 'user_10', 'inv_10', 'invoice', '/exports/pdf_10.pdf')
ON CONFLICT DO NOTHING;
