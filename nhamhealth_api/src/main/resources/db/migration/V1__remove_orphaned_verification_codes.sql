-- Verification codes are short-lived authentication artifacts. Older databases
-- may contain rows whose user was deleted before the foreign key existed.
-- Remove only those unusable rows so Hibernate can safely create the FK.
DELETE FROM public.verification_codes AS verification_code
WHERE verification_code.user_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM public.users AS app_user
    WHERE app_user.user_id = verification_code.user_id
  );
