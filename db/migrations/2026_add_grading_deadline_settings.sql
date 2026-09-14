-- =====================================================================
-- Baholash muddati — admin tomonidan sozlanadigan tizim darajasidagi
-- sozlama. Bitta qatorli ("singleton") jadval: id har doim 1.
--
-- ISHLATISH: psql -h 10.240.255.90 -p 5432 -U postgres -d EduLog -f grading_deadline_migration.sql
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.grading_deadline_settings (
    id SMALLINT PRIMARY KEY DEFAULT 1,
    normal_lesson_hours INTEGER NOT NULL DEFAULT 20,
    control_lesson_hours INTEGER NOT NULL DEFAULT 72,
    updated_by_admin_id INTEGER,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT grading_deadline_settings_single_row CHECK (id = 1)
);

-- Avvalgi qattiq yozilgan qiymatlar (20 soat / 72 soat) bilan bir xil
-- standart qiymatlar bilan boshlanadi — mavjud xatti-harakat o'zgarmaydi,
-- admin xohlagan vaqtda sozlamalar oynasidan o'zgartira oladi.
INSERT INTO public.grading_deadline_settings (id, normal_lesson_hours, control_lesson_hours)
VALUES (1, 20, 72)
ON CONFLICT (id) DO NOTHING;
