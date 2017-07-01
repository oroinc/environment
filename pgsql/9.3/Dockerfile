FROM postgres:9.3

ENV PGDATA /var/lib/postgres_data

ARG DUMP="empty.sql.gz"

ENV POSTGRES_DB oro_db

RUN mkdir -p /var/lib/postgres_lock && chown -R postgres:postgres /var/lib/postgres_lock && chmod 777 /var/lib/postgres_lock
RUN touch /var/lib/postgres_lock/db_lock

COPY conf/uuid.sql /docker-entrypoint-initdb.d/10_uuid.sql
COPY dumps/$DUMP /docker-entrypoint-initdb.d/20_dump.sql.gz
COPY conf/unlock.sh /docker-entrypoint-initdb.d/30_unlock.sh
