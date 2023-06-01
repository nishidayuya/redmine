FROM ruby:3.1.4-slim-bullseye

ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND noninteractive

RUN set -eux && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    brz \
    build-essential \
    chromium \
    chromium-driver \
    cvs \
    fonts-ipafont \
    git \
    libmagickwand-6.q16-dev \
    libpq-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxslt-dev \
    mercurial \
    openssh-client \
    postgresql-client \
    subversion \
    tzdata
RUN set -eux && \
    install -m 700 -o root -g root -d -v /root/.ssh && \
    (echo Host github.com && echo '  StrictHostKeyChecking no') | tee /root/.ssh/config && \
    git config --global url.'git@github.com:'.insteadOf https://github.com/

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
