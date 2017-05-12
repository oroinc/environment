FROM postgres:9.5

ENV PGDATA /var/lib/postgres_data

COPY conf/uuid.sql /docker-entrypoint-initdb.d/uuid.sql
