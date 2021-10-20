FROM python:3.8.5

ADD data-models data-models

RUN apt-get update -y && \
  apt-get install --no-install-recommends -y -q \
  git libpq-dev python-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pip install -U pip
RUN pip install -r data-models/requirements.txt
ENV LANG C.UTF-8
ENV PYTHONIOENCODING utf-8

WORKDIR /