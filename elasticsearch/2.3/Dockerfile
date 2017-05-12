FROM elasticsearch:2.3
RUN bin/plugin install delete-by-query
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["elasticsearch"]
