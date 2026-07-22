-- Preserve the company and role metadata for Auth users created by a manager.
-- Run this migration in Supabase SQL Editor after the manager-account migration.
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
