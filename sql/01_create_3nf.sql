-- =============================================================================
-- ЛР №2. Вариант 1. Модель 3NF
-- Предметная область: порядок подготовки к экзамену (цель — отличная оценка)
-- СУБД: PostgreSQL 16
-- Схема: n3nf
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS n3nf;

-- ---------------------------------------------------------------------------
-- Справочники и базовые сущности
-- ---------------------------------------------------------------------------

CREATE TABLE n3nf.student (
    student_id      SERIAL PRIMARY KEY,
    student_code    VARCHAR(32)  NOT NULL UNIQUE,
    full_name       VARCHAR(200) NOT NULL,
    email           VARCHAR(200),
    group_code      VARCHAR(32)  NOT NULL
);

COMMENT ON TABLE  n3nf.student IS 'Студент, готовящийся к экзамену';
COMMENT ON COLUMN n3nf.student.student_code IS 'Бизнес-ключ / номер зачётки';
COMMENT ON COLUMN n3nf.student.group_code IS 'Учебная группа';

CREATE TABLE n3nf.discipline (
    discipline_id   SERIAL PRIMARY KEY,
    discipline_code VARCHAR(32)  NOT NULL UNIQUE,
    title           VARCHAR(200) NOT NULL,
    hours_total     INTEGER      NOT NULL CHECK (hours_total > 0)
);

COMMENT ON TABLE  n3nf.discipline IS 'Учебная дисциплина';
COMMENT ON COLUMN n3nf.discipline.discipline_code IS 'Код дисциплины (бизнес-ключ)';

CREATE TABLE n3nf.teacher (
    teacher_id      SERIAL PRIMARY KEY,
    teacher_code    VARCHAR(32)  NOT NULL UNIQUE,
    full_name       VARCHAR(200) NOT NULL,
    department      VARCHAR(200)
);

COMMENT ON TABLE n3nf.teacher IS 'Преподаватель, принимающий экзамен';

CREATE TABLE n3nf.grade_scale (
    grade_scale_id  SERIAL PRIMARY KEY,
    grade_label     VARCHAR(32)  NOT NULL UNIQUE,
    min_score       NUMERIC(5,2) NOT NULL CHECK (min_score >= 0),
    max_score       NUMERIC(5,2) NOT NULL CHECK (max_score <= 100),
    CONSTRAINT chk_grade_score_range CHECK (min_score <= max_score)
);

COMMENT ON TABLE  n3nf.grade_scale IS 'Шкала оценок; для цели «отлично» используется соответствующая запись';
COMMENT ON COLUMN n3nf.grade_scale.min_score IS 'Минимальный балл для данной оценки';

-- ---------------------------------------------------------------------------
-- Экзамен и содержание
-- ---------------------------------------------------------------------------

CREATE TABLE n3nf.exam (
    exam_id         SERIAL PRIMARY KEY,
    exam_code       VARCHAR(32)  NOT NULL UNIQUE,
    discipline_id   INTEGER      NOT NULL REFERENCES n3nf.discipline (discipline_id),
    teacher_id      INTEGER      NOT NULL REFERENCES n3nf.teacher (teacher_id),
    exam_date       DATE         NOT NULL,
    max_score       NUMERIC(5,2) NOT NULL DEFAULT 100 CHECK (max_score > 0),
    location        VARCHAR(200)
);

COMMENT ON TABLE  n3nf.exam IS 'Экзамен по дисциплине';
COMMENT ON COLUMN n3nf.exam.exam_code IS 'Бизнес-ключ экзамена';

CREATE INDEX idx_exam_discipline ON n3nf.exam (discipline_id);
CREATE INDEX idx_exam_teacher    ON n3nf.exam (teacher_id);

CREATE TABLE n3nf.topic (
    topic_id        SERIAL PRIMARY KEY,
    topic_code      VARCHAR(32)  NOT NULL UNIQUE,
    exam_id         INTEGER      NOT NULL REFERENCES n3nf.exam (exam_id),
    title           VARCHAR(300) NOT NULL,
    weight_pct      NUMERIC(5,2) NOT NULL DEFAULT 0
        CHECK (weight_pct >= 0 AND weight_pct <= 100),
    sort_order      INTEGER      NOT NULL DEFAULT 1 CHECK (sort_order > 0)
);

COMMENT ON TABLE  n3nf.topic IS 'Тема экзамена (вопрос / раздел программы)';
COMMENT ON COLUMN n3nf.topic.weight_pct IS 'Доля темы в итоговой оценке, %';

CREATE INDEX idx_topic_exam ON n3nf.topic (exam_id);

CREATE TABLE n3nf.material (
    material_id     SERIAL PRIMARY KEY,
    material_code   VARCHAR(32)  NOT NULL UNIQUE,
    title           VARCHAR(300) NOT NULL,
    material_type   VARCHAR(64)  NOT NULL,
    url_or_ref      VARCHAR(500),
    estimated_hours NUMERIC(6,2) CHECK (estimated_hours IS NULL OR estimated_hours >= 0)
);

COMMENT ON TABLE  n3nf.material IS 'Учебный материал (учебник, конспект, задача, видео и т.п.)';
COMMENT ON COLUMN n3nf.material.material_type IS 'Тип: textbook, notes, problems, video, other';

CREATE TABLE n3nf.topic_material (
    topic_id        INTEGER NOT NULL REFERENCES n3nf.topic (topic_id),
    material_id     INTEGER NOT NULL REFERENCES n3nf.material (material_id),
    is_required     BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (topic_id, material_id)
);

COMMENT ON TABLE n3nf.topic_material IS 'Связь M:N тема — учебный материал';

-- ---------------------------------------------------------------------------
-- План подготовки и этапы
-- ---------------------------------------------------------------------------

CREATE TABLE n3nf.preparation_plan (
    plan_id         SERIAL PRIMARY KEY,
    plan_code       VARCHAR(32)  NOT NULL UNIQUE,
    student_id      INTEGER      NOT NULL REFERENCES n3nf.student (student_id),
    exam_id         INTEGER      NOT NULL REFERENCES n3nf.exam (exam_id),
    target_grade_id INTEGER      NOT NULL REFERENCES n3nf.grade_scale (grade_scale_id),
    start_date      DATE         NOT NULL,
    end_date        DATE         NOT NULL,
    status          VARCHAR(32)  NOT NULL DEFAULT 'active',
    CONSTRAINT chk_plan_dates CHECK (start_date <= end_date),
    CONSTRAINT uq_student_exam_plan UNIQUE (student_id, exam_id)
);

COMMENT ON TABLE  n3nf.preparation_plan IS 'План подготовки студента к экзамену с целевой оценкой (отлично)';
COMMENT ON COLUMN n3nf.preparation_plan.target_grade_id IS 'Целевая оценка по шкале (обычно «отлично»)';
COMMENT ON COLUMN n3nf.preparation_plan.status IS 'active | completed | cancelled';

CREATE INDEX idx_plan_student ON n3nf.preparation_plan (student_id);
CREATE INDEX idx_plan_exam    ON n3nf.preparation_plan (exam_id);

CREATE TABLE n3nf.plan_stage (
    stage_id        SERIAL PRIMARY KEY,
    plan_id         INTEGER      NOT NULL REFERENCES n3nf.preparation_plan (plan_id) ON DELETE CASCADE,
    stage_no        INTEGER      NOT NULL CHECK (stage_no > 0),
    stage_name      VARCHAR(120) NOT NULL,
    planned_hours   NUMERIC(6,2) NOT NULL CHECK (planned_hours >= 0),
    description     TEXT,
    CONSTRAINT uq_plan_stage_no UNIQUE (plan_id, stage_no)
);

COMMENT ON TABLE  n3nf.plan_stage IS 'Этап плана: теория → практика → пробный экзамен → повторение';
COMMENT ON COLUMN n3nf.plan_stage.stage_no IS 'Порядковый номер этапа в плане';

CREATE INDEX idx_stage_plan ON n3nf.plan_stage (plan_id);

CREATE TABLE n3nf.stage_task (
    task_id         SERIAL PRIMARY KEY,
    task_code       VARCHAR(32)  NOT NULL UNIQUE,
    stage_id        INTEGER      NOT NULL REFERENCES n3nf.plan_stage (stage_id) ON DELETE CASCADE,
    topic_id        INTEGER      REFERENCES n3nf.topic (topic_id),
    title           VARCHAR(300) NOT NULL,
    due_date        DATE,
    planned_hours   NUMERIC(6,2) NOT NULL DEFAULT 1 CHECK (planned_hours >= 0),
    priority        SMALLINT     NOT NULL DEFAULT 3 CHECK (priority BETWEEN 1 AND 5)
);

COMMENT ON TABLE  n3nf.stage_task IS 'Конкретное задание на этапе подготовки';
COMMENT ON COLUMN n3nf.stage_task.topic_id IS 'Опциональная привязка к теме экзамена';
COMMENT ON COLUMN n3nf.stage_task.priority IS '1 — высший приоритет, 5 — низший';

CREATE INDEX idx_task_stage ON n3nf.stage_task (stage_id);
CREATE INDEX idx_task_topic ON n3nf.stage_task (topic_id);

-- ---------------------------------------------------------------------------
-- Факты выполнения и самопроверки
-- ---------------------------------------------------------------------------

CREATE TABLE n3nf.task_completion (
    completion_id   SERIAL PRIMARY KEY,
    task_id         INTEGER      NOT NULL REFERENCES n3nf.stage_task (task_id),
    completed_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actual_hours    NUMERIC(6,2) NOT NULL CHECK (actual_hours >= 0),
    note            TEXT,
    CONSTRAINT uq_task_completion_once UNIQUE (task_id)
);

COMMENT ON TABLE n3nf.task_completion IS 'Факт выполнения задания (один раз на задание)';

CREATE INDEX idx_completion_task ON n3nf.task_completion (task_id);

CREATE TABLE n3nf.practice_result (
    practice_id     SERIAL PRIMARY KEY,
    plan_id         INTEGER      NOT NULL REFERENCES n3nf.preparation_plan (plan_id) ON DELETE CASCADE,
    practice_date   DATE         NOT NULL,
    score           NUMERIC(5,2) NOT NULL CHECK (score >= 0),
    max_score       NUMERIC(5,2) NOT NULL DEFAULT 100 CHECK (max_score > 0),
    is_mock_exam    BOOLEAN      NOT NULL DEFAULT FALSE,
    comment         TEXT,
    CONSTRAINT chk_practice_score CHECK (score <= max_score)
);

COMMENT ON TABLE  n3nf.practice_result IS 'Результат самопроверки или пробного экзамена';
COMMENT ON COLUMN n3nf.practice_result.is_mock_exam IS 'TRUE — полноценный пробный экзамен';

CREATE INDEX idx_practice_plan ON n3nf.practice_result (plan_id);
