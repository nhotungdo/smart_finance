-- 1. COMPANY
CREATE TABLE public.companies (
    company_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name TEXT NOT NULL,
    tax_code TEXT,
    address TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. ROLE
CREATE TABLE public.roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name TEXT NOT NULL UNIQUE,
    description TEXT
);

-- 3. USER
CREATE TABLE public.users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Thường sẽ map với auth.users(id) khi tích hợp Authentication
    company_id UUID REFERENCES public.companies(company_id),
    role_id UUID REFERENCES public.roles(role_id),
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT,
    phone TEXT,
    status TEXT NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'DELETED')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. CATEGORY
CREATE TABLE public.categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES public.companies(company_id),
    category_name TEXT NOT NULL,
    category_type TEXT NOT NULL
        CHECK (category_type IN ('INCOME', 'EXPENSE')),
    icon_name TEXT,
    color_code TEXT,
    is_default BOOLEAN DEFAULT false,
    status TEXT NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'DELETED')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. INVOICE
CREATE TABLE public.invoices (
    invoice_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES public.companies(company_id),
    uploaded_by UUID REFERENCES public.users(user_id),
    supplier_name TEXT,
    supplier_tax_code TEXT,
    invoice_number TEXT,
    invoice_date DATE,
    subtotal INTEGER,
    vat_rate INTEGER,
    vat_amount INTEGER,
    total_amount INTEGER,
    image_path TEXT,
    scan_status TEXT NOT NULL DEFAULT 'NOT_SCANNED'
        CHECK (scan_status IN ('NOT_SCANNED', 'SCANNING', 'SCANNED', 'ERROR')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. TRANSACTION
CREATE TABLE public.transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES public.companies(company_id),
    category_id UUID REFERENCES public.categories(category_id),
    created_by UUID REFERENCES public.users(user_id),
    invoice_id UUID REFERENCES public.invoices(invoice_id),
    amount INTEGER NOT NULL,
    transaction_type TEXT NOT NULL
        CHECK (transaction_type IN ('INCOME', 'EXPENSE')),
    transaction_date DATE NOT NULL,
    description TEXT,
    receipt_image_path TEXT,
    status TEXT NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'DELETED')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. OCR_RESULT
CREATE TABLE public.ocr_results (
    ocr_result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID REFERENCES public.invoices(invoice_id) ON DELETE CASCADE,
    extracted_supplier_name TEXT,
    extracted_tax_code TEXT,
    extracted_amount INTEGER,
    raw_mock_data JSONB,
    status TEXT NOT NULL DEFAULT 'SCANNED'
        CHECK (status IN ('NOT_SCANNED', 'SCANNING', 'SCANNED', 'ERROR')),
    scanned_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. PDF_EXPORT
CREATE TABLE public.pdf_exports (
    pdf_export_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES public.companies(company_id),
    exported_by UUID REFERENCES public.users(user_id),
    invoice_id UUID REFERENCES public.invoices(invoice_id),
    export_type TEXT NOT NULL,
    file_path TEXT NOT NULL,
    exported_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX categories_company_name_type_active_idx
ON public.categories (
    COALESCE(company_id::text, ''),
    LOWER(BTRIM(category_name)),
    category_type
)
WHERE status = 'ACTIVE';
