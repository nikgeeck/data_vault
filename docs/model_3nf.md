# Даталогическая модель 3NF (вариант 1)

**Предметная область:** порядок подготовки к экзамену с целью получить отличную оценку.  
**СУБД:** PostgreSQL, схема `n3nf`.  
**DDL:** [sql/01_create_3nf.sql](../sql/01_create_3nf.sql).

## Назначение модели

Операционная (OLTP-подобная) модель хранит актуальные сущности процесса подготовки: кто готовится, к какому экзамену, по каким темам и материалам, какие этапы и задания запланированы, что уже выполнено и какие результаты пробных проверок получены.

## Обоснование 3NF

1. **1NF** — все атрибуты атомарны (нет массивов и составных значений в одном поле).
2. **2NF** — нет частичных зависимостей от составного ключа: таблицы с составным PK (`topic_material`) содержат только атрибуты, зависящие от всей пары ключей.
3. **3NF** — нет транзитивных зависимостей: название дисциплины не хранится в `exam`, а берётся через `discipline_id`; целевая оценка не денормализована в план, а ссылается на `grade_scale`.

## Сущности

| Таблица | Ключ | Описание |
|--------|------|----------|
| `student` | `student_id` / `student_code` | Студент |
| `discipline` | `discipline_id` / `discipline_code` | Дисциплина |
| `teacher` | `teacher_id` / `teacher_code` | Преподаватель |
| `grade_scale` | `grade_scale_id` / `grade_label` | Шкала оценок (в т.ч. «отлично») |
| `exam` | `exam_id` / `exam_code` | Экзамен (дисциплина + преподаватель + дата) |
| `topic` | `topic_id` / `topic_code` | Тема экзамена |
| `material` | `material_id` / `material_code` | Учебный материал |
| `topic_material` | `(topic_id, material_id)` | Связь тема–материал |
| `preparation_plan` | `plan_id` / `plan_code` | План подготовки студента к экзамену |
| `plan_stage` | `stage_id` | Этап плана (порядок подготовки) |
| `stage_task` | `task_id` / `task_code` | Задание на этапе |
| `task_completion` | `completion_id` | Факт выполнения задания |
| `practice_result` | `practice_id` | Результат самопроверки / пробного экзамена |

## ER-диаграмма

```mermaid
erDiagram
  student ||--o{ preparation_plan : has
  exam ||--o{ preparation_plan : for
  exam }o--|| discipline : of
  exam }o--|| teacher : conducted_by
  exam ||--o{ topic : contains
  topic ||--o{ topic_material : uses
  material ||--o{ topic_material : used_in
  preparation_plan ||--o{ plan_stage : ordered
  preparation_plan }o--|| grade_scale : target
  plan_stage ||--o{ stage_task : includes
  topic ||--o{ stage_task : focuses
  stage_task ||--o| task_completion : logged
  preparation_plan ||--o{ practice_result : checks

  student {
    int student_id PK
    varchar student_code UK
    varchar full_name
    varchar group_code
  }
  discipline {
    int discipline_id PK
    varchar discipline_code UK
    varchar title
    int hours_total
  }
  teacher {
    int teacher_id PK
    varchar teacher_code UK
    varchar full_name
  }
  exam {
    int exam_id PK
    varchar exam_code UK
    int discipline_id FK
    int teacher_id FK
    date exam_date
  }
  topic {
    int topic_id PK
    varchar topic_code UK
    int exam_id FK
    varchar title
    numeric weight_pct
  }
  material {
    int material_id PK
    varchar material_code UK
    varchar title
    varchar material_type
  }
  topic_material {
    int topic_id PK_FK
    int material_id PK_FK
    boolean is_required
  }
  grade_scale {
    int grade_scale_id PK
    varchar grade_label UK
    numeric min_score
    numeric max_score
  }
  preparation_plan {
    int plan_id PK
    varchar plan_code UK
    int student_id FK
    int exam_id FK
    int target_grade_id FK
    date start_date
    date end_date
  }
  plan_stage {
    int stage_id PK
    int plan_id FK
    int stage_no
    varchar stage_name
  }
  stage_task {
    int task_id PK
    varchar task_code UK
    int stage_id FK
    int topic_id FK
    varchar title
  }
  task_completion {
    int completion_id PK
    int task_id FK
    timestamp completed_at
    numeric actual_hours
  }
  practice_result {
    int practice_id PK
    int plan_id FK
    date practice_date
    numeric score
    boolean is_mock_exam
  }
```

## Типовой порядок подготовки (логический процесс)

1. Студент создаёт `preparation_plan` на экзамен с целевой оценкой «отлично» (`grade_scale`).
2. План разбивается на упорядоченные `plan_stage` (теория, практика, пробный, повторение).
3. На этапах задаются `stage_task`, при необходимости привязанные к `topic` и обеспеченные `material`.
4. Выполнение фиксируется в `task_completion`, прогресс по баллам — в `practice_result`.
