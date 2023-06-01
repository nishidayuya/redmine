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
      ghostscript \
      git \
      imagemagick \
      libmagickwand-6.q16-dev \
      libpq-dev \
      libsqlite3-dev \
      libxml2-dev \
      libxslt-dev \
      mercurial \
      openssh-client \
      postgresql-client \
      subversion \
      tzdata && \
    rm -rf /var/lib/apt/lists/*

# Install Mercurial 3.7.3
#
# https://redmine.org/projects/redmine/wiki/Continuous_integration
RUN set -eux && \
    apt-get update && \
    development_dependencies=' \
      libpython2.7-dev \
      python2.7 \
      wget \
    ' && \
    apt-get install -y --no-install-recommends $development_dependencies && \
    mkdir /tmp/mercurial && \
    cd /tmp/mercurial && \
    wget https://www.mercurial-scm.org/release/mercurial-3.7.3.tar.gz && \
    tar xf mercurial-3.7.3.tar.gz && \
    cd mercurial-3.7.3/ && \
    python2.7 setup.py install && \
    cd / && \
    rm -rf /tmp/mercurial && \
    apt-get purge -y $development_dependencies && \
    apt-get autopurge -y && \
    rm -rf /var/lib/apt/lists/*

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
