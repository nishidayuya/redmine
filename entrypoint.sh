#!/bin/sh

set -eux

bundle
bin/rake generate_secret_token
bin/rake db:create
bin/rake db:migrate
bin/rake redmine:plugins:migrate
bin/rake db:migrate:status

exec "$@"
