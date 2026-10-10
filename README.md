# ЛР №2: 3NF и Data Vault (вариант 1)

Предметная область: **система подготовки к экзамену с целью получить отличную оценку**.

| Артефакт | Описание |
|----------|----------|
| [docs/model_3nf.md](docs/model_3nf.md) | Даталогическая модель 3NF |
| [docs/model_data_vault.md](docs/model_data_vault.md) | Даталогическая модель Data Vault |
| [sql/01_create_3nf.sql](sql/01_create_3nf.sql) | DDL схемы `n3nf` |
| [sql/02_create_data_vault.sql](sql/02_create_data_vault.sql) | DDL схемы `dv` |
| [sql/03_sample_data_3nf.sql](sql/03_sample_data_3nf.sql) | Демо-данные для 3NF |

## Требования

- Docker Desktop (или Docker Engine + Compose v2)

## Запуск PostgreSQL

Из‑за кириллицы в пути каталога задайте имя проекта явно:

```bash
cd "/Users/nikitavolodin/Desktop/шарага/ХД"
export COMPOSE_PROJECT_NAME=exam_prep
docker compose up -d
```

Параметры подключения:

- host: `localhost`
- port: `5432`
- database: `exam_prep`
- user / password: `postgres` / `postgres`

## Применение скриптов

Дождитесь готовности контейнера, затем:

```bash
export COMPOSE_PROJECT_NAME=exam_prep
docker compose exec -T db psql -U postgres -d exam_prep < sql/01_create_3nf.sql
docker compose exec -T db psql -U postgres -d exam_prep < sql/02_create_data_vault.sql
docker compose exec -T db psql -U postgres -d exam_prep < sql/03_sample_data_3nf.sql
```

Проверка объектов:

```bash
docker compose exec -T db psql -U postgres -d exam_prep -c '\dt n3nf.*'
docker compose exec -T db psql -U postgres -d exam_prep -c '\dt dv.*'
```

## Остановка

```bash
export COMPOSE_PROJECT_NAME=exam_prep
docker compose down
```

Данные в volume сохраняются. Полная очистка:

```bash
docker compose down -v
```
