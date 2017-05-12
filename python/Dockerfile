FROM python:2.7-alpine

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh

ADD requirements.txt /requirements.txt

RUN pip install --upgrade -r /requirements.txt

VOLUME ['/documentation']
WORKDIR '/documentation'

CMD sphinx-build -nW -b html -d _build/doctrees . _build/html
