-- Canonical SmartFinance categories and cleanup for legacy duplicates.
-- Safe to run repeatedly in the Supabase SQL Editor.

BEGIN;

DROP INDEX IF EXISTS public.categories_company_name_type_active_idx;

UPDATE public.categories
SET category_name = 'Lương', updated_at = NOW()
WHERE category_type = 'EXPENSE'
  AND BTRIM(category_name) IN ('Tiền lương', 'tiền lương');

WITH defaults(category_key, category_name, category_type, icon_name, color_code) AS (
  VALUES
    ('expense:food', 'Ăn uống', 'EXPENSE', 'restaurant', '#F44336'),
    ('expense:travel', 'Du lịch', 'EXPENSE', 'flight', '#2196F3'),
    ('expense:office', 'Văn phòng', 'EXPENSE', 'computer', '#4CAF50'),
    ('expense:fuel', 'Xăng xe', 'EXPENSE', 'local_gas_station', '#FF9800'),
    ('expense:salary', 'Lương', 'EXPENSE', 'payments', '#E11D48'),
    ('income:sales', 'Doanh thu bán hàng', 'INCOME', 'attach_money', '#8BC34A')
)
INSERT INTO public.categories (
  category_id,
  company_id,
  category_name,
  category_type,
  icon_name,
  color_code,
  is_default,
  status,
  created_at,
  updated_at,
  is_synced
)
SELECT
  'default:' || company.company_id || ':' || defaults.category_key,
  company.company_id,
  defaults.category_name,
  defaults.category_type,
  defaults.icon_name,
  defaults.color_code,
  1,
  'ACTIVE',
  NOW(),
  NOW(),
  1
FROM public.companies AS company
CROSS JOIN defaults
ON CONFLICT (category_id) DO UPDATE SET
  company_id = EXCLUDED.company_id,
  category_name = EXCLUDED.category_name,
  category_type = EXCLUDED.category_type,
  icon_name = EXCLUDED.icon_name,
  color_code = EXCLUDED.color_code,
  is_default = 1,
  status = 'ACTIVE',
  updated_at = NOW();

WITH defaults(category_key, category_name, category_type) AS (
  VALUES
    ('expense:food', 'Ăn uống', 'EXPENSE'),
    ('expense:travel', 'Du lịch', 'EXPENSE'),
    ('expense:office', 'Văn phòng', 'EXPENSE'),
    ('expense:fuel', 'Xăng xe', 'EXPENSE'),
    ('expense:salary', 'Lương', 'EXPENSE'),
    ('income:sales', 'Doanh thu bán hàng', 'INCOME')
), category_remap AS (
  SELECT
    category.category_id AS old_id,
    'default:' || category.company_id || ':' || defaults.category_key AS canonical_id
  FROM public.categories AS category
  JOIN defaults
    ON LOWER(BTRIM(category.category_name)) = LOWER(defaults.category_name)
   AND category.category_type = defaults.category_type
  WHERE category.company_id IS NOT NULL
)
UPDATE public.transactions AS transaction
SET category_id = category_remap.canonical_id
FROM category_remap
WHERE transaction.category_id = category_remap.old_id
  AND category_remap.old_id <> category_remap.canonical_id;

WITH defaults(category_key, category_name, category_type) AS (
  VALUES
    ('expense:food', 'Ăn uống', 'EXPENSE'),
    ('expense:travel', 'Du lịch', 'EXPENSE'),
    ('expense:office', 'Văn phòng', 'EXPENSE'),
    ('expense:fuel', 'Xăng xe', 'EXPENSE'),
    ('expense:salary', 'Lương', 'EXPENSE'),
    ('income:sales', 'Doanh thu bán hàng', 'INCOME')
)
DELETE FROM public.categories AS category
USING defaults
WHERE category.company_id IS NOT NULL
  AND LOWER(BTRIM(category.category_name)) = LOWER(defaults.category_name)
  AND category.category_type = defaults.category_type
  AND category.category_id <>
      'default:' || category.company_id || ':' || defaults.category_key;

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
UPDATE public.transactions AS transaction
SET category_id = ranked.canonical_id
FROM ranked_categories AS ranked
WHERE transaction.category_id = ranked.category_id
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

CREATE UNIQUE INDEX categories_company_name_type_active_idx
ON public.categories (
  COALESCE(company_id, ''),
  LOWER(BTRIM(category_name)),
  category_type
)
WHERE status = 'ACTIVE';

COMMIT;

NOTIFY pgrst, 'reload schema';
