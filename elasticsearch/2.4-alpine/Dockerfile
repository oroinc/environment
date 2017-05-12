FROM elasticsearch:2.4-alpine
RUN bin/plugin install delete-by-query
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["elasticsearch"]
