FROM mysql:5.7

COPY conf/data.cnf /etc/mysql/conf.d/data.cnf

ARG DUMP="empty.sql.gz"

ENV MYSQL_DATABASE oro_db

RUN chmod 644 /etc/mysql/conf.d/data.cnf && \
    rm -rf /var/lib/mysql_data && \
    mkdir -p /var/lib/mysql_data && \
    touch /var/lib/mysql_data/db_lock && \
    chown -R mysql:mysql /var/lib/mysql_data

COPY dumps/$DUMP /docker-entrypoint-initdb.d/10_dump.sql.gz
COPY conf/unlock.sh /docker-entrypoint-initdb.d/20_unlock.sh
