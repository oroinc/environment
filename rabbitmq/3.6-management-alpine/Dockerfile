FROM rabbitmq:3.6.8-management-alpine
RUN apk --update add curl
RUN curl http://www.rabbitmq.com/community-plugins/v3.6.x/rabbitmq_delayed_message_exchange-0.0.1.ez > $RABBITMQ_HOME/plugins/rabbitmq_delayed_message_exchange-0.0.1.ez
RUN rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange
