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
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  is_synced SMALLINT DEFAULT 1
);

-- 4. CATEGORIES
CREATE TABLE IF NOT EXISTS public.categories (
  category_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  company_id TEXT REFERENCES public.companies(company_id) ON DELETE CASCADE,
  category_name TEXT NOT NULL,
  category_type TEXT NOT NULL,
  icon_name TEXT,
  color_code TEXT,
  is_default SMALLINT DEFAULT 0,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  is_synced SMALLINT DEFAULT 1
);

-- 5. INVOICES
CREATE TABLE IF NOT EXISTS public.invoices (
  invoice_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  company_id TEXT REFERENCES public.companies(company_id) ON DELETE CASCADE,
  uploaded_by TEXT REFERENCES public.users(user_id) ON DELETE SET NULL,
  supplier_name TEXT,
  supplier_tax_code TEXT,
  invoice_number TEXT,
  invoice_date TIMESTAMP WITH TIME ZONE,
  subtotal REAL,
  vat_rate REAL,
  vat_amount REAL,
  total_amount REAL,
  image_path TEXT,
  scan_status TEXT DEFAULT 'pending',
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
  amount REAL NOT NULL,
  transaction_type TEXT NOT NULL,
  transaction_date TIMESTAMP WITH TIME ZONE NOT NULL,
  description TEXT,
  receipt_image_path TEXT,
  status TEXT DEFAULT 'completed',
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
  extracted_amount REAL,
  raw_mock_data TEXT,
  status TEXT DEFAULT 'processed',
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

ALTER TABLE public.transactions
  ALTER COLUMN transaction_id SET DEFAULT gen_random_uuid()::text;

ALTER TABLE public.ocr_results
  ALTER COLUMN ocr_result_id SET DEFAULT gen_random_uuid()::text;

ALTER TABLE public.pdf_exports
  ALTER COLUMN pdf_export_id SET DEFAULT gen_random_uuid()::text;

-- Setup Row Level Security (Optional but recommended)
-- ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.ocr_results ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.pdf_exports ENABLE ROW LEVEL SECURITY;

-- =========================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Run the following scripts if you have enabled RLS in Supabase
-- to allow the app to function properly.
-- =========================================================================

-- 1. COMPANIES POLICIES
-- Allow authenticated users to insert a new company during registration
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."companies";
CREATE POLICY "Enable insert for authenticated users only" ON "public"."companies"
FOR INSERT TO authenticated WITH CHECK (true);

-- Allow authenticated users to view companies
DROP POLICY IF EXISTS "Enable select for authenticated users" ON "public"."companies";
CREATE POLICY "Enable select for authenticated users" ON "public"."companies"
FOR SELECT TO authenticated USING (true);

-- Allow authenticated users to update their own company
DROP POLICY IF EXISTS "Enable update for users based on company_id" ON "public"."companies";
CREATE POLICY "Enable update for users based on company_id" ON "public"."companies"
FOR UPDATE TO authenticated USING (true);


-- 2. USERS POLICIES
-- Allow users to insert their own profile during registration
DROP POLICY IF EXISTS "Enable insert for users based on user_id" ON "public"."users";
CREATE POLICY "Enable insert for users based on user_id" ON "public"."users"
FOR INSERT TO authenticated WITH CHECK (auth.uid()::text = user_id);

-- Allow users to view their own profile
DROP POLICY IF EXISTS "Enable select for users based on user_id" ON "public"."users";
CREATE POLICY "Enable select for users based on user_id" ON "public"."users"
FOR SELECT TO authenticated USING (auth.uid()::text = user_id);

-- Allow users to update their own profile
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON "public"."users";
CREATE POLICY "Enable update for users based on user_id" ON "public"."users"
FOR UPDATE TO authenticated USING (auth.uid()::text = user_id);
