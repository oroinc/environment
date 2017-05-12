FROM mysql:5.5

COPY conf/data.cnf /etc/mysql/conf.d/data.cnf

RUN chmod 644 /etc/mysql/conf.d/data.cnf && \
    rm -rf /var/lib/mysql_data && \
    mkdir -p /var/lib/mysql_data && \
    chown -R mysql:mysql /var/lib/mysql_data
