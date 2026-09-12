-- =====================================================================
-- EduLog (Ejurnal) — Performance indekslar
-- Maqsad: o'qituvchi uchun menu.php va u ishlatadigan AJAX so'rovlarini
-- (get_teacher_day_lessons.php, get_today_lessons.php,
--  get_lesson_grading_data.php, save_lesson_grade.php,
--  load_calendar_plan.php, get_report.php, get_monthly_hours.php,
--  get_hour_balance_report.php, test_bank_actions.php) tezlashtirish.
--
-- MUHIM: PostgreSQL foreign key ustunlariga index'ni AVTOMATIK
-- QO'YMAYDI (faqat PRIMARY KEY uchun qo'yiladi). Shu sababli
-- calendar_plan, grades, teachersubjects, weekly_schedule kabi
-- jadvallarda WHERE/JOIN uchun ishlatiladigan ustunlarga qo'lda
-- index qo'shish shart.
--
-- ISHLATISH:
--   psql -h 10.240.255.90 -p 5432 -U postgres -d EduLog -f add_indexes.sql
--
-- DIQQAT: bu skriptni psql orqali TO'G'RIDAN-TO'G'RI ishga tushiring
-- (BEGIN...COMMIT bilan o'rab QO'YMANG). CREATE INDEX CONCURRENTLY
-- tranzaksiya ichida ishlamaydi — u ataylab shunday yozilgan, chunki
-- CONCURRENTLY jadvalni QULFLAMAY (write'larni to'xtatmay) index yaratadi.
-- Oddiy CREATE INDEX katta jadvallarda bir necha soniya/daqiqaga
-- yozishni bloklab qo'yishi mumkin — CONCURRENTLY buni oldini oladi.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) calendar_plan — eng ko'p ishlatiladigan, eng "og'ir" jadval
-- ---------------------------------------------------------------------

-- Bugungi/ertangi darslar paneli (get_teacher_day_lessons.php)
-- WHERE cp.teacher_id = :uid AND cp.topic_date >= ... AND cp.topic_date < ...
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cp_teacher_topic_date
    ON public.calendar_plan (teacher_id, topic_date);

-- Fan/guruh ro'yxati (menu.php), oylik hisobot, soat-limit subso'rovi
-- WHERE cp.graded_by_teacher_id = :uid [AND cp.group_id=... AND cp.subject_id=... AND cp.semester_id=...]
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cp_graded_group_subject_sem
    ON public.calendar_plan (graded_by_teacher_id, group_id, subject_id, semester_id);

-- O'qituvchining fan+semestr+yil kesimidagi barcha darslari (test bank)
-- WHERE cp.teacher_id=:uid AND cp.subject_id=:s AND cp.semester_id=:sem AND cp.academic_year_id=:y
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cp_teacher_subject_sem_year
    ON public.calendar_plan (teacher_id, subject_id, semester_id, academic_year_id);

-- "Shaxsiy reja" ro'yxati (load_calendar_plan.php) va hisobot (get_report.php)
-- WHERE cp.subject_id=:s AND cp.group_id=:g AND cp.academic_year_id=:y [AND cp.semester_id=:sem]
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cp_subject_group_year_sem
    ON public.calendar_plan (subject_id, group_id, academic_year_id, semester_id);

-- Kunlik jadval (barcha guruhlar), soat balansi hisoboti — faol o'quv yili bo'yicha
-- WHERE cp.academic_year_id = :y
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cp_academic_year_id
    ON public.calendar_plan (academic_year_id);

-- topic_date bo'yicha saralash/oraliq so'rovlar (ORDER BY cp.topic_date, oylik hisobot EXTRACT(...))
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cp_topic_date
    ON public.calendar_plan (topic_date);


-- ---------------------------------------------------------------------
-- 2) grades — har bir baho ko'rish/saqlashda ishlatiladi
-- ---------------------------------------------------------------------

-- WHERE student_id=:sid AND calendar_plan_id=:pid  (tekshirish/UPDATE/DELETE)
-- va WHERE calendar_plan_id IN (...)  (get_report.php)
-- calendar_plan_id oldinda turishi ikkala holatga ham xizmat qiladi.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_grades_plan_student
    ON public.grades (calendar_plan_id, student_id);


-- ---------------------------------------------------------------------
-- 3) test_attempts — test natijalarini ko'rsatish (get_lesson_grading_data.php)
-- ---------------------------------------------------------------------

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_test_attempts_student_plan_attempt
    ON public.test_attempts (student_id, calendar_plan_id, attempt_number);


-- ---------------------------------------------------------------------
-- 4) test_topic_links — darsga biriktirilgan test mavzusini topish
-- ---------------------------------------------------------------------

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_test_topic_links_calendar_plan_id
    ON public.test_topic_links (calendar_plan_id);


-- ---------------------------------------------------------------------
-- 5) teachersubjects — yillik soat / limit hisob-kitoblari
-- ---------------------------------------------------------------------

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_teachersubjects_teacher_subject_group_sem
    ON public.teachersubjects (teacher_id, subject_id, group_id, semester_id);


-- ---------------------------------------------------------------------
-- 6) weekly_schedule — dars jadvali (menu.php) va bugungi darslar (barcha guruh)
-- ---------------------------------------------------------------------

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_weekly_schedule_teacher_year
    ON public.weekly_schedule (teacher_id, academic_year_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_weekly_schedule_group_year_sem
    ON public.weekly_schedule (group_id, academic_year_id, semester_id);


-- ---------------------------------------------------------------------
-- 7) students — guruh bo'yicha talabalar ro'yxati (baholash oynasi, hisobot)
-- ---------------------------------------------------------------------

-- Faqat arxivlanmagan talabalar deyarli har doim kerak bo'lgani uchun
-- partial index — kichikroq va tezroq.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_students_group_active
    ON public.students (id_group) WHERE archived_at IS NULL;


-- ---------------------------------------------------------------------
-- 8) semester_schedule — semestr sanalarini aniqlash
-- ---------------------------------------------------------------------

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_semester_schedule_year_semester
    ON public.semester_schedule (academic_year_id, semester_id);


-- ---------------------------------------------------------------------
-- Statistikani yangilash — Postgres query planner yangi indekslardan
-- to'g'ri foydalanishi uchun shart.
-- ---------------------------------------------------------------------

ANALYZE public.calendar_plan;
ANALYZE public.grades;
ANALYZE public.test_attempts;
ANALYZE public.test_topic_links;
ANALYZE public.teachersubjects;
ANALYZE public.weekly_schedule;
ANALYZE public.students;
ANALYZE public.semester_schedule;
