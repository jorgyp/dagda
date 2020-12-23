FROM python:3.6.4-alpine3.6
COPY requirements.txt /opt/app/requirements.txt
WORKDIR /opt/app
RUN pip install -r requirements.txt
COPY dagda /opt/app
COPY ./dockerfiles/run.sh /
RUN chmod +x /run.sh
RUN apk add --update docker openrc
RUN rc-update add docker boot

ENTRYPOINT ["/bin/sh","/run.sh"]
