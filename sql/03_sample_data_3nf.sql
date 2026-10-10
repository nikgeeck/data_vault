-- =============================================================================
-- ЛР №2. Вариант 1. Демо-данные для схемы n3nf
-- =============================================================================

INSERT INTO n3nf.grade_scale (grade_label, min_score, max_score) VALUES
    ('неудовлетворительно', 0, 39.99),
    ('удовлетворительно', 40, 59.99),
    ('хорошо', 60, 84.99),
    ('отлично', 85, 100);

INSERT INTO n3nf.student (student_code, full_name, email, group_code) VALUES
    ('S-001', 'Иванов Иван Иванович', 'ivanov@university.local', 'ИС-21'),
    ('S-002', 'Петрова Анна Сергеевна', 'petrova@university.local', 'ИС-21');

INSERT INTO n3nf.discipline (discipline_code, title, hours_total) VALUES
    ('DWH-101', 'Хранилища данных', 108);

INSERT INTO n3nf.teacher (teacher_code, full_name, department) VALUES
    ('T-10', 'Сидорова Е.В.', 'Кафедра ИТ');

INSERT INTO n3nf.exam (exam_code, discipline_id, teacher_id, exam_date, max_score, location)
SELECT 'EX-DWH-2026', d.discipline_id, t.teacher_id, DATE '2026-06-15', 100, 'ауд. 301'
FROM n3nf.discipline d, n3nf.teacher t
WHERE d.discipline_code = 'DWH-101' AND t.teacher_code = 'T-10';

INSERT INTO n3nf.topic (topic_code, exam_id, title, weight_pct, sort_order)
SELECT v.topic_code, e.exam_id, v.title, v.weight_pct, v.sort_order
FROM n3nf.exam e
CROSS JOIN (VALUES
    ('TP-01', 'Моделирование 3NF', 25.00, 1),
    ('TP-02', 'Data Vault: Hub / Link / Satellite', 35.00, 2),
    ('TP-03', 'ETL и слои хранилища', 40.00, 3)
) AS v(topic_code, title, weight_pct, sort_order)
WHERE e.exam_code = 'EX-DWH-2026';

INSERT INTO n3nf.material (material_code, title, material_type, url_or_ref, estimated_hours) VALUES
    ('M-01', 'Все о Data Vault (DWH-Club)', 'article',
     'http://www.dwh-club.com/ru/dwh-bi-articles/vse-o-data-vault.html', 2),
    ('M-02', 'Конспект лекций по 3NF', 'notes', 'campus://dwh/3nf-notes', 4),
    ('M-03', 'Сборник задач по моделированию', 'problems', 'campus://dwh/tasks', 6);

INSERT INTO n3nf.topic_material (topic_id, material_id, is_required)
SELECT t.topic_id, m.material_id, TRUE
FROM n3nf.topic t
JOIN n3nf.material m ON TRUE
WHERE (t.topic_code = 'TP-01' AND m.material_code = 'M-02')
   OR (t.topic_code = 'TP-02' AND m.material_code = 'M-01')
   OR (t.topic_code = 'TP-03' AND m.material_code = 'M-03');

INSERT INTO n3nf.preparation_plan (
    plan_code, student_id, exam_id, target_grade_id, start_date, end_date, status
)
SELECT
    'PLAN-S001-EX',
    s.student_id,
    e.exam_id,
    g.grade_scale_id,
    DATE '2026-05-01',
    DATE '2026-06-14',
    'active'
FROM n3nf.student s
JOIN n3nf.exam e ON e.exam_code = 'EX-DWH-2026'
JOIN n3nf.grade_scale g ON g.grade_label = 'отлично'
WHERE s.student_code = 'S-001';

INSERT INTO n3nf.plan_stage (plan_id, stage_no, stage_name, planned_hours, description)
SELECT p.plan_id, v.stage_no, v.stage_name, v.planned_hours, v.description
FROM n3nf.preparation_plan p
CROSS JOIN (VALUES
    (1, 'Теория', 12.0, 'Изучение конспектов и статьи по Data Vault'),
    (2, 'Практика', 16.0, 'Решение задач и построение моделей'),
    (3, 'Пробный экзамен', 4.0, 'Полный пробный вариант'),
    (4, 'Повторение', 8.0, 'Закрепление слабых тем')
) AS v(stage_no, stage_name, planned_hours, description)
WHERE p.plan_code = 'PLAN-S001-EX';

INSERT INTO n3nf.stage_task (task_code, stage_id, topic_id, title, due_date, planned_hours, priority)
SELECT
    'TSK-01',
    st.stage_id,
    tp.topic_id,
    'Прочитать статью о Data Vault и законспектировать Hub/Link/Sat',
    DATE '2026-05-10',
    3.0,
    1
FROM n3nf.plan_stage st
JOIN n3nf.preparation_plan p ON p.plan_id = st.plan_id
JOIN n3nf.topic tp ON tp.topic_code = 'TP-02'
WHERE p.plan_code = 'PLAN-S001-EX' AND st.stage_no = 1;

INSERT INTO n3nf.stage_task (task_code, stage_id, topic_id, title, due_date, planned_hours, priority)
SELECT
    'TSK-02',
    st.stage_id,
    tp.topic_id,
    'Спроектировать 3NF для предметной области варианта',
    DATE '2026-05-20',
    5.0,
    1
FROM n3nf.plan_stage st
JOIN n3nf.preparation_plan p ON p.plan_id = st.plan_id
JOIN n3nf.topic tp ON tp.topic_code = 'TP-01'
WHERE p.plan_code = 'PLAN-S001-EX' AND st.stage_no = 2;

INSERT INTO n3nf.task_completion (task_id, completed_at, actual_hours, note)
SELECT task_id, TIMESTAMP '2026-05-09 18:30:00', 2.5, 'Конспект готов'
FROM n3nf.stage_task
WHERE task_code = 'TSK-01';

INSERT INTO n3nf.practice_result (plan_id, practice_date, score, max_score, is_mock_exam, comment)
SELECT p.plan_id, DATE '2026-05-25', 78, 100, FALSE, 'Самопроверка по темам 1–2'
FROM n3nf.preparation_plan p
WHERE p.plan_code = 'PLAN-S001-EX';

INSERT INTO n3nf.practice_result (plan_id, practice_date, score, max_score, is_mock_exam, comment)
SELECT p.plan_id, DATE '2026-06-05', 88, 100, TRUE, 'Пробный экзамен: цель «отлично» достигнута'
FROM n3nf.preparation_plan p
WHERE p.plan_code = 'PLAN-S001-EX';
