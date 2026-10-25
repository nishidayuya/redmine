#!/bin/sh

# Entry point of the "web" and "sidekiq" services of docker-compose.yml: waits
# until post_create_command.d in the "app" container has installed the gems and
# migrated the database, then runs the given command.

set -eu

until bundle check > /dev/null 2>&1 &&
  bundle exec rake db:abort_if_pending_migrations > /dev/null 2>&1
do
  echo "$0: waiting for post_create_command.d to set up gems and database..." >&2
  sleep 5
done

exec "$@"
