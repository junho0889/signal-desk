#!/bin/sh
set -eu

require_env() {
  name="$1"
  eval "value=\${$name:-}"
  if [ -z "$value" ]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

for var in POSTGRES_DB POSTGRES_APP_USER POSTGRES_APP_PASSWORD POSTGRES_MIGRATOR_USER POSTGRES_MIGRATOR_PASSWORD POSTGRES_READONLY_USER POSTGRES_READONLY_PASSWORD; do
  require_env "$var"
done

create_role() {
  role_name="$1"
  role_password="$2"

  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres --set=role_name="$role_name" --set=role_password="$role_password" <<'SQL'
SELECT format(
  'CREATE ROLE %I LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT',
  :'role_name',
  :'role_password'
)
WHERE NOT EXISTS (
  SELECT 1 FROM pg_roles WHERE rolname = :'role_name'
)\gexec
SQL
}

create_database() {
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres --set=db_name="$POSTGRES_DB" <<'SQL'
SELECT format('CREATE DATABASE %I', :'db_name')
WHERE NOT EXISTS (
  SELECT 1 FROM pg_database WHERE datname = :'db_name'
)\gexec
SQL
}

create_role "$POSTGRES_MIGRATOR_USER" "$POSTGRES_MIGRATOR_PASSWORD"
create_role "$POSTGRES_APP_USER" "$POSTGRES_APP_PASSWORD"
create_role "$POSTGRES_READONLY_USER" "$POSTGRES_READONLY_PASSWORD"
create_database

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres --set=db_name="$POSTGRES_DB" --set=migrator_user="$POSTGRES_MIGRATOR_USER" --set=app_user="$POSTGRES_APP_USER" --set=readonly_user="$POSTGRES_READONLY_USER" <<'SQL'
SELECT format('ALTER DATABASE %I OWNER TO %I', :'db_name', :'migrator_user')\gexec
SELECT format('REVOKE ALL ON DATABASE %I FROM PUBLIC', :'db_name')\gexec
SELECT format('GRANT CONNECT ON DATABASE %I TO %I', :'db_name', :'migrator_user')\gexec
SELECT format('GRANT CONNECT ON DATABASE %I TO %I', :'db_name', :'app_user')\gexec
SELECT format('GRANT CONNECT ON DATABASE %I TO %I', :'db_name', :'readonly_user')\gexec
SQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --set=migrator_user="$POSTGRES_MIGRATOR_USER" --set=app_user="$POSTGRES_APP_USER" --set=readonly_user="$POSTGRES_READONLY_USER" <<'SQL'
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
SELECT format('ALTER SCHEMA public OWNER TO %I', :'migrator_user')\gexec
SELECT format('GRANT USAGE, CREATE ON SCHEMA public TO %I', :'migrator_user')\gexec
SELECT format('GRANT USAGE ON SCHEMA public TO %I', :'app_user')\gexec
SELECT format('GRANT USAGE ON SCHEMA public TO %I', :'readonly_user')\gexec
SELECT format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I', :'migrator_user', :'app_user')\gexec
SELECT format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO %I', :'migrator_user', :'app_user')\gexec
SELECT format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA public GRANT SELECT ON TABLES TO %I', :'migrator_user', :'readonly_user')\gexec
SELECT format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA public GRANT SELECT ON SEQUENCES TO %I', :'migrator_user', :'readonly_user')\gexec
SQL
