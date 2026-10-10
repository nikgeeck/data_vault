-- =============================================================================
-- ЛР №2. Вариант 1. Модель Data Vault
-- Предметная область: порядок подготовки к экзамену (цель — отличная оценка)
-- СУБД: PostgreSQL 16
-- Схема: dv
-- Стиль: Data Vault 2.0-light (hash-ключи BYTEA, load_dts, record_source, hashdiff)
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS dv;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------
-- HUBS: бизнес-ключи + метаданные загрузки
-- ---------------------------------------------------------------------------

CREATE TABLE dv.hub_student (
    hk_student      BYTEA       PRIMARY KEY,
    bk_student      VARCHAR(32) NOT NULL UNIQUE,
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL
);

COMMENT ON TABLE  dv.hub_student IS 'Hub: студент (бизнес-ключ = student_code)';
COMMENT ON COLUMN dv.hub_student.hk_student IS 'Hash-ключ от бизнес-ключа';
COMMENT ON COLUMN dv.hub_student.bk_student IS 'Бизнес-ключ студента';
COMMENT ON COLUMN dv.hub_student.load_dts IS 'Дата/время загрузки записи';
COMMENT ON COLUMN dv.hub_student.record_source IS 'Источник записи';

CREATE TABLE dv.hub_discipline (
    hk_discipline   BYTEA       PRIMARY KEY,
    bk_discipline   VARCHAR(32) NOT NULL UNIQUE,
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL
);

COMMENT ON TABLE dv.hub_discipline IS 'Hub: дисциплина';

CREATE TABLE dv.hub_teacher (
    hk_teacher      BYTEA       PRIMARY KEY,
    bk_teacher      VARCHAR(32) NOT NULL UNIQUE,
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL
);

COMMENT ON TABLE dv.hub_teacher IS 'Hub: преподаватель';

CREATE TABLE dv.hub_exam (
    hk_exam         BYTEA       PRIMARY KEY,
    bk_exam         VARCHAR(32) NOT NULL UNIQUE,
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL
);

COMMENT ON TABLE dv.hub_exam IS 'Hub: экзамен';

CREATE TABLE dv.hub_topic (
    hk_topic        BYTEA       PRIMARY KEY,
    bk_topic        VARCHAR(32) NOT NULL UNIQUE,
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL
);

COMMENT ON TABLE dv.hub_topic IS 'Hub: тема экзамена';

CREATE TABLE dv.hub_material (
    hk_material     BYTEA       PRIMARY KEY,
    bk_material     VARCHAR(32) NOT NULL UNIQUE,
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL
);

COMMENT ON TABLE dv.hub_material IS 'Hub: учебный материал';

CREATE TABLE dv.hub_plan (
    hk_plan         BYTEA       PRIMARY KEY,
    bk_plan         VARCHAR(32) NOT NULL UNIQUE,
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL
);

COMMENT ON TABLE dv.hub_plan IS 'Hub: план подготовки';

CREATE TABLE dv.hub_task (
    hk_task         BYTEA       PRIMARY KEY,
    bk_task         VARCHAR(32) NOT NULL UNIQUE,
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL
);

COMMENT ON TABLE dv.hub_task IS 'Hub: задание этапа подготовки';

CREATE TABLE dv.hub_grade_scale (
    hk_grade_scale  BYTEA       PRIMARY KEY,
    bk_grade_scale  VARCHAR(32) NOT NULL UNIQUE,
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL
);

COMMENT ON TABLE dv.hub_grade_scale IS 'Hub: метка оценки (отлично, хорошо, ...)';

-- ---------------------------------------------------------------------------
-- LINKS: связи между хабами
-- ---------------------------------------------------------------------------

CREATE TABLE dv.link_exam_discipline_teacher (
    hk_link         BYTEA       PRIMARY KEY,
    hk_exam         BYTEA       NOT NULL REFERENCES dv.hub_exam (hk_exam),
    hk_discipline   BYTEA       NOT NULL REFERENCES dv.hub_discipline (hk_discipline),
    hk_teacher      BYTEA       NOT NULL REFERENCES dv.hub_teacher (hk_teacher),
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL,
    CONSTRAINT uq_link_exam_disc_teacher UNIQUE (hk_exam, hk_discipline, hk_teacher)
);

COMMENT ON TABLE dv.link_exam_discipline_teacher IS 'Link: экзамен — дисциплина — преподаватель';

CREATE TABLE dv.link_exam_topic (
    hk_link         BYTEA       PRIMARY KEY,
    hk_exam         BYTEA       NOT NULL REFERENCES dv.hub_exam (hk_exam),
    hk_topic        BYTEA       NOT NULL REFERENCES dv.hub_topic (hk_topic),
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL,
    CONSTRAINT uq_link_exam_topic UNIQUE (hk_exam, hk_topic)
);

COMMENT ON TABLE dv.link_exam_topic IS 'Link: экзамен — тема';

CREATE TABLE dv.link_topic_material (
    hk_link         BYTEA       PRIMARY KEY,
    hk_topic        BYTEA       NOT NULL REFERENCES dv.hub_topic (hk_topic),
    hk_material     BYTEA       NOT NULL REFERENCES dv.hub_material (hk_material),
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL,
    CONSTRAINT uq_link_topic_material UNIQUE (hk_topic, hk_material)
);

COMMENT ON TABLE dv.link_topic_material IS 'Link: тема — материал';

CREATE TABLE dv.link_plan_student_exam (
    hk_link         BYTEA       PRIMARY KEY,
    hk_plan         BYTEA       NOT NULL REFERENCES dv.hub_plan (hk_plan),
    hk_student      BYTEA       NOT NULL REFERENCES dv.hub_student (hk_student),
    hk_exam         BYTEA       NOT NULL REFERENCES dv.hub_exam (hk_exam),
    hk_grade_scale  BYTEA       NOT NULL REFERENCES dv.hub_grade_scale (hk_grade_scale),
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL,
    CONSTRAINT uq_link_plan_student_exam UNIQUE (hk_plan, hk_student, hk_exam)
);

COMMENT ON TABLE dv.link_plan_student_exam IS 'Link: план — студент — экзамен — целевая оценка';

CREATE TABLE dv.link_plan_stage_task (
    hk_link         BYTEA       PRIMARY KEY,
    hk_plan         BYTEA       NOT NULL REFERENCES dv.hub_plan (hk_plan),
    hk_task         BYTEA       NOT NULL REFERENCES dv.hub_task (hk_task),
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL,
    CONSTRAINT uq_link_plan_task UNIQUE (hk_plan, hk_task)
);

COMMENT ON TABLE dv.link_plan_stage_task IS 'Link: план — задание (этапность описывается в satellite)';

CREATE TABLE dv.link_task_topic (
    hk_link         BYTEA       PRIMARY KEY,
    hk_task         BYTEA       NOT NULL REFERENCES dv.hub_task (hk_task),
    hk_topic        BYTEA       NOT NULL REFERENCES dv.hub_topic (hk_topic),
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL,
    CONSTRAINT uq_link_task_topic UNIQUE (hk_task, hk_topic)
);

COMMENT ON TABLE dv.link_task_topic IS 'Link: задание — тема экзамена';

CREATE TABLE dv.link_task_completion (
    hk_link         BYTEA       PRIMARY KEY,
    hk_task         BYTEA       NOT NULL REFERENCES dv.hub_task (hk_task),
    hk_student      BYTEA       NOT NULL REFERENCES dv.hub_student (hk_student),
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL,
    CONSTRAINT uq_link_task_completion UNIQUE (hk_task, hk_student)
);

COMMENT ON TABLE dv.link_task_completion IS 'Link: факт выполнения задания студентом';

CREATE TABLE dv.link_practice_result (
    hk_link         BYTEA       PRIMARY KEY,
    hk_plan         BYTEA       NOT NULL REFERENCES dv.hub_plan (hk_plan),
    hk_student      BYTEA       NOT NULL REFERENCES dv.hub_student (hk_student),
    load_dts        TIMESTAMP   NOT NULL,
    record_source   VARCHAR(64) NOT NULL
);

COMMENT ON TABLE dv.link_practice_result IS 'Link: результат практики / пробного экзамена по плану студента';

CREATE INDEX idx_lpr_plan    ON dv.link_practice_result (hk_plan);
CREATE INDEX idx_lpr_student ON dv.link_practice_result (hk_student);

-- ---------------------------------------------------------------------------
-- SATELLITES: описательные атрибуты + история (insert-only)
-- PK = (hash родителя, load_dts)
-- ---------------------------------------------------------------------------

CREATE TABLE dv.sat_student_details (
    hk_student      BYTEA       NOT NULL REFERENCES dv.hub_student (hk_student),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    full_name       VARCHAR(200) NOT NULL,
    email           VARCHAR(200),
    group_code      VARCHAR(32)  NOT NULL,
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_student, load_dts)
);

COMMENT ON TABLE dv.sat_student_details IS 'Satellite: атрибуты студента';

CREATE TABLE dv.sat_discipline_details (
    hk_discipline   BYTEA       NOT NULL REFERENCES dv.hub_discipline (hk_discipline),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    title           VARCHAR(200) NOT NULL,
    hours_total     INTEGER      NOT NULL,
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_discipline, load_dts)
);

COMMENT ON TABLE dv.sat_discipline_details IS 'Satellite: атрибуты дисциплины';

CREATE TABLE dv.sat_teacher_details (
    hk_teacher      BYTEA       NOT NULL REFERENCES dv.hub_teacher (hk_teacher),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    full_name       VARCHAR(200) NOT NULL,
    department      VARCHAR(200),
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_teacher, load_dts)
);

COMMENT ON TABLE dv.sat_teacher_details IS 'Satellite: атрибуты преподавателя';

CREATE TABLE dv.sat_exam_details (
    hk_exam         BYTEA       NOT NULL REFERENCES dv.hub_exam (hk_exam),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    exam_date       DATE         NOT NULL,
    max_score       NUMERIC(5,2) NOT NULL,
    location        VARCHAR(200),
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_exam, load_dts)
);

COMMENT ON TABLE dv.sat_exam_details IS 'Satellite: атрибуты экзамена';

CREATE TABLE dv.sat_topic_details (
    hk_topic        BYTEA       NOT NULL REFERENCES dv.hub_topic (hk_topic),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    title           VARCHAR(300) NOT NULL,
    weight_pct      NUMERIC(5,2) NOT NULL,
    sort_order      INTEGER      NOT NULL,
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_topic, load_dts)
);

COMMENT ON TABLE dv.sat_topic_details IS 'Satellite: атрибуты темы';

CREATE TABLE dv.sat_material_details (
    hk_material     BYTEA       NOT NULL REFERENCES dv.hub_material (hk_material),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    title           VARCHAR(300) NOT NULL,
    material_type   VARCHAR(64)  NOT NULL,
    url_or_ref      VARCHAR(500),
    estimated_hours NUMERIC(6,2),
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_material, load_dts)
);

COMMENT ON TABLE dv.sat_material_details IS 'Satellite: атрибуты материала';

CREATE TABLE dv.sat_grade_scale_details (
    hk_grade_scale  BYTEA       NOT NULL REFERENCES dv.hub_grade_scale (hk_grade_scale),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    min_score       NUMERIC(5,2) NOT NULL,
    max_score       NUMERIC(5,2) NOT NULL,
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_grade_scale, load_dts)
);

COMMENT ON TABLE dv.sat_grade_scale_details IS 'Satellite: диапазон баллов оценки';

CREATE TABLE dv.sat_plan_details (
    hk_plan         BYTEA       NOT NULL REFERENCES dv.hub_plan (hk_plan),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    start_date      DATE         NOT NULL,
    end_date        DATE         NOT NULL,
    status          VARCHAR(32)  NOT NULL,
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_plan, load_dts)
);

COMMENT ON TABLE dv.sat_plan_details IS 'Satellite: атрибуты плана подготовки';

CREATE TABLE dv.sat_topic_material_details (
    hk_link         BYTEA       NOT NULL REFERENCES dv.link_topic_material (hk_link),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    is_required     BOOLEAN      NOT NULL,
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_link, load_dts)
);

COMMENT ON TABLE dv.sat_topic_material_details IS 'Satellite на Link: обязательность материала для темы';

CREATE TABLE dv.sat_stage_details (
    hk_link         BYTEA       NOT NULL REFERENCES dv.link_plan_stage_task (hk_link),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    stage_no        INTEGER      NOT NULL,
    stage_name      VARCHAR(120) NOT NULL,
    planned_hours   NUMERIC(6,2) NOT NULL,
    description     TEXT,
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_link, load_dts)
);

COMMENT ON TABLE dv.sat_stage_details IS 'Satellite на Link план–задание: сведения об этапе';

CREATE TABLE dv.sat_task_details (
    hk_task         BYTEA       NOT NULL REFERENCES dv.hub_task (hk_task),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    title           VARCHAR(300) NOT NULL,
    due_date        DATE,
    planned_hours   NUMERIC(6,2) NOT NULL,
    priority        SMALLINT     NOT NULL,
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_task, load_dts)
);

COMMENT ON TABLE dv.sat_task_details IS 'Satellite: атрибуты задания';

CREATE TABLE dv.sat_completion_details (
    hk_link         BYTEA       NOT NULL REFERENCES dv.link_task_completion (hk_link),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    completed_at    TIMESTAMP    NOT NULL,
    actual_hours    NUMERIC(6,2) NOT NULL,
    note            TEXT,
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_link, load_dts)
);

COMMENT ON TABLE dv.sat_completion_details IS 'Satellite: детали выполнения задания';

CREATE TABLE dv.sat_practice_details (
    hk_link         BYTEA       NOT NULL REFERENCES dv.link_practice_result (hk_link),
    load_dts        TIMESTAMP   NOT NULL,
    hashdiff        BYTEA       NOT NULL,
    practice_date   DATE         NOT NULL,
    score           NUMERIC(5,2) NOT NULL,
    max_score       NUMERIC(5,2) NOT NULL,
    is_mock_exam    BOOLEAN      NOT NULL,
    comment         TEXT,
    record_source   VARCHAR(64)  NOT NULL,
    PRIMARY KEY (hk_link, load_dts)
);

COMMENT ON TABLE dv.sat_practice_details IS 'Satellite: баллы и комментарий практики / пробного экзамена';
