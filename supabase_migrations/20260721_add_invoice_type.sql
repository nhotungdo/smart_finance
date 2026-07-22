-- Adds the invoice direction required by the current mobile/web/desktop app.
-- Safe to run more than once in the Supabase SQL Editor.

BEGIN;

ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS invoice_type TEXT;

UPDATE public.invoices
SET invoice_type = CASE
  WHEN UPPER(COALESCE(invoice_type, '')) = 'INCOME' THEN 'INCOME'
  ELSE 'EXPENSE'
END;

ALTER TABLE public.invoices
  ALTER COLUMN invoice_type SET DEFAULT 'EXPENSE',
  ALTER COLUMN invoice_type SET NOT NULL;

ALTER TABLE public.invoices
  DROP CONSTRAINT IF EXISTS invoices_invoice_type_check;

ALTER TABLE public.invoices
  ADD CONSTRAINT invoices_invoice_type_check
  CHECK (invoice_type IN ('INCOME', 'EXPENSE'));

COMMIT;

-- Refresh the PostgREST schema cache used by Supabase Data API.
NOTIFY pgrst, 'reload schema';
