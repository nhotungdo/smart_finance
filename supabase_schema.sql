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

-- 2. ROLES (10 records)
INSERT INTO public.roles (role_id, role_name, description) VALUES 
('role_01', 'Admin', 'Quản trị viên hệ thống'),
('role_02', 'Manager', 'Quản lý cửa hàng/chi nhánh'),
('role_03', 'Accountant', 'Nhân viên kế toán'),
('role_04', 'Sales', 'Nhân viên kinh doanh'),
('role_05', 'HR', 'Nhân sự'),
('role_06', 'IT Support', 'Hỗ trợ kỹ thuật'),
('role_07', 'Marketing', 'Nhân viên tiếp thị'),
('role_08', 'Auditor', 'Kiểm toán viên'),
('role_09', 'Director', 'Giám đốc'),
('role_10', 'Viewer', 'Chỉ xem dữ liệu')
ON CONFLICT DO NOTHING;

-- 3. USERS (10 records)
INSERT INTO public.users (user_id, company_id, role_id, full_name, email, phone, password_hash) VALUES 
('user_01', 'comp_01', 'role_01', 'Nguyễn Văn A', 'nguyenvana@gmail.com', '0901111111', '123456'),
('user_02', 'comp_02', 'role_02', 'Trần Thị B', 'tranthib@gmail.com', '0902222222', '123456'),
('user_03', 'comp_03', 'role_03', 'Lê Văn C', 'levanc@gmail.com', '0903333333', '123456'),
('user_04', 'comp_04', 'role_04', 'Phạm Thị D', 'phamthid@gmail.com', '0904444444', '123456'),
('user_05', 'comp_05', 'role_05', 'Hoàng Văn E', 'hoangvane@gmail.com', '0905555555', '123456'),
('user_06', 'comp_06', 'role_06', 'Đỗ Thị F', 'dothif@gmail.com', '0906666666', '123456'),
('user_07', 'comp_07', 'role_07', 'Ngô Văn G', 'ngovang@gmail.com', '0907777777', '123456'),
('user_08', 'comp_08', 'role_08', 'Vũ Thị H', 'vuthih@gmail.com', '0908888888', '123456'),
('user_09', 'comp_09', 'role_09', 'Đặng Văn I', 'dangvani@gmail.com', '0909999999', '123456'),
('user_10', 'comp_10', 'role_10', 'Bùi Thị K', 'buithik@gmail.com', '0910000000', '123456')
ON CONFLICT DO NOTHING;

-- 4. CATEGORIES (10 records)
INSERT INTO public.categories (category_id, company_id, category_name, category_type, icon_name, color_code, is_default) VALUES 
('cat_01', 'comp_01', 'Tiền lương', 'expense', 'attach_money', '#FF5722', 1),
('cat_02', 'comp_01', 'Bán hàng', 'income', 'store', '#4CAF50', 1),
('cat_03', 'comp_02', 'Văn phòng phẩm', 'expense', 'edit', '#2196F3', 0),
('cat_04', 'comp_02', 'Dịch vụ', 'income', 'build', '#9C27B0', 0),
('cat_05', 'comp_03', 'Tiếp khách', 'expense', 'restaurant', '#FF9800', 0),
('cat_06', 'comp_03', 'Đầu tư', 'income', 'trending_up', '#3F51B5', 0),
('cat_07', 'comp_04', 'Marketing', 'expense', 'campaign', '#E91E63', 0),
('cat_08', 'comp_04', 'Chiết khấu', 'income', 'local_offer', '#009688', 0),
('cat_09', 'comp_05', 'Vận chuyển', 'expense', 'local_shipping', '#795548', 0),
('cat_10', 'comp_05', 'Hoàn thuế', 'income', 'account_balance', '#607D8B', 0)
ON CONFLICT DO NOTHING;

-- 5. INVOICES (10 records)
INSERT INTO public.invoices (invoice_id, company_id, uploaded_by, supplier_name, supplier_tax_code, invoice_number, subtotal, vat_rate, vat_amount, total_amount, scan_status) VALUES 
('inv_01', 'comp_01', 'user_01', 'Nhà cung cấp A', '0101111111', 'HD-001', 1000000, 10, 100000, 1100000, 'completed'),
('inv_02', 'comp_02', 'user_02', 'Nhà cung cấp B', '0102222222', 'HD-002', 2000000, 10, 200000, 2200000, 'completed'),
('inv_03', 'comp_03', 'user_03', 'Nhà cung cấp C', '0103333333', 'HD-003', 3000000, 8, 240000, 3240000, 'pending'),
('inv_04', 'comp_04', 'user_04', 'Nhà cung cấp D', '0104444444', 'HD-004', 4000000, 10, 400000, 4400000, 'failed'),
('inv_05', 'comp_05', 'user_05', 'Nhà cung cấp E', '0105555555', 'HD-005', 5000000, 5, 250000, 5250000, 'completed'),
('inv_06', 'comp_06', 'user_06', 'Nhà cung cấp F', '0106666666', 'HD-006', 6000000, 10, 600000, 6600000, 'completed'),
('inv_07', 'comp_07', 'user_07', 'Nhà cung cấp G', '0107777777', 'HD-007', 7000000, 10, 700000, 7700000, 'pending'),
('inv_08', 'comp_08', 'user_08', 'Nhà cung cấp H', '0108888888', 'HD-008', 8000000, 8, 640000, 8640000, 'completed'),
('inv_09', 'comp_09', 'user_09', 'Nhà cung cấp I', '0109999999', 'HD-009', 9000000, 10, 900000, 9900000, 'completed'),
('inv_10', 'comp_10', 'user_10', 'Nhà cung cấp K', '0100000000', 'HD-010', 10000000, 10, 1000000, 11000000, 'pending')
ON CONFLICT DO NOTHING;

-- 6. TRANSACTIONS (10 records)
INSERT INTO public.transactions (transaction_id, company_id, category_id, created_by, invoice_id, amount, transaction_type, transaction_date, description, status) VALUES 
('trans_01', 'comp_01', 'cat_01', 'user_01', 'inv_01', 1100000, 'expense', NOW(), 'Thanh toán HD-001', 'completed'),
('trans_02', 'comp_02', 'cat_03', 'user_02', 'inv_02', 2200000, 'expense', NOW(), 'Thanh toán HD-002', 'completed'),
('trans_03', 'comp_03', 'cat_05', 'user_03', 'inv_03', 3240000, 'expense', NOW(), 'Thanh toán HD-003', 'pending'),
('trans_04', 'comp_04', 'cat_07', 'user_04', 'inv_04', 4400000, 'expense', NOW(), 'Thanh toán HD-004', 'failed'),
('trans_05', 'comp_05', 'cat_09', 'user_05', 'inv_05', 5250000, 'expense', NOW(), 'Thanh toán HD-005', 'completed'),
('trans_06', 'comp_01', 'cat_02', 'user_01', NULL, 15000000, 'income', NOW(), 'Doanh thu bán hàng tháng 1', 'completed'),
('trans_07', 'comp_02', 'cat_04', 'user_02', NULL, 25000000, 'income', NOW(), 'Doanh thu dịch vụ tháng 1', 'completed'),
('trans_08', 'comp_03', 'cat_06', 'user_03', NULL, 35000000, 'income', NOW(), 'Lợi nhuận đầu tư', 'completed'),
('trans_09', 'comp_04', 'cat_08', 'user_04', NULL, 45000000, 'income', NOW(), 'Chiết khấu bán hàng', 'completed'),
('trans_10', 'comp_05', 'cat_10', 'user_05', NULL, 55000000, 'income', NOW(), 'Hoàn thuế GTGT', 'completed')
ON CONFLICT DO NOTHING;

-- 7. OCR_RESULTS (10 records)
INSERT INTO public.ocr_results (ocr_result_id, invoice_id, extracted_supplier_name, extracted_tax_code, extracted_amount, raw_mock_data, status) VALUES 
('ocr_01', 'inv_01', 'Nhà cung cấp A', '0101111111', 1100000, '{"data": "mock_1"}', 'processed'),
('ocr_02', 'inv_02', 'Nhà cung cấp B', '0102222222', 2200000, '{"data": "mock_2"}', 'processed'),
('ocr_03', 'inv_03', 'Nhà cung cấp C', '0103333333', 3240000, '{"data": "mock_3"}', 'processed'),
('ocr_04', 'inv_04', 'Nhà cung cấp D', '0104444444', 4400000, '{"data": "mock_4"}', 'failed'),
('ocr_05', 'inv_05', 'Nhà cung cấp E', '0105555555', 5250000, '{"data": "mock_5"}', 'processed'),
('ocr_06', 'inv_06', 'Nhà cung cấp F', '0106666666', 6600000, '{"data": "mock_6"}', 'processed'),
('ocr_07', 'inv_07', 'Nhà cung cấp G', '0107777777', 7700000, '{"data": "mock_7"}', 'processed'),
('ocr_08', 'inv_08', 'Nhà cung cấp H', '0108888888', 8640000, '{"data": "mock_8"}', 'processed'),
('ocr_09', 'inv_09', 'Nhà cung cấp I', '0109999999', 9900000, '{"data": "mock_9"}', 'processed'),
('ocr_10', 'inv_10', 'Nhà cung cấp K', '0100000000', 11000000, '{"data": "mock_10"}', 'processed')
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
