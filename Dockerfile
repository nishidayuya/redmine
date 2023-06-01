FROM ruby:2.6.6-slim-buster

ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND noninteractive

RUN set -eux && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    build-essential \
    chromium \
    chromium-driver \
    git \
    libmagickwand-6.q16-dev \
    libpq-dev \
    libxml2-dev \
    libxslt-dev \
    openssh-client \
    postgresql-client-11 \
    tzdata
RUN set -eux && \
    install -m 700 -o root -g root -d -v /root/.ssh && \
    (echo Host github.com && echo '  StrictHostKeyChecking no') | tee /root/.ssh/config && \
    git config --global url.'git@github.com:'.insteadOf https://github.com/
RUN set -eux && \
  apt-get install -y --no-install-recommends \
    libsqlite3-dev

WORKDIR /opt/app
COPY Gemfile ./
COPY config/database.yml ./config/

RUN set -eux && \
    gem install bundler && \
    bundle install && \
    bundle clean --force

EXPOSE 3000
ENTRYPOINT ["./entrypoint.sh"]
CMD ["bin/rails", "server", "--binding=0.0.0.0"]

COPY . /opt/app
