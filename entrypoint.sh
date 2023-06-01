#!/bin/sh

set -eux

bundle
bin/rails \
  generate_secret_token &&
  db:create &&
  db:migrate &&
  db:migrate:status

exec "$@"
