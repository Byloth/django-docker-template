# Happy 😄

A template of a ready-to-use dockerized Django application.

## Get started

### Build

```sh
docker compose build
```

### First run

```sh
docker compose up -d postgres
docker compose exec postgres psql -U postgres
```

```psql
CREATE USER happy WITH PASSWORD 'happy00';
CREATE DATABASE happy WITH OWNER happy;
\q
```

```sh
docker compose up -d
docker compose exec django ./manage.py migrate
docker compose exec django ./manage.py createsuperuser
```

### Run

```python
docker compose up [-d]
```
