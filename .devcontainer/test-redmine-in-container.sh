#!/bin/bash

# Runs inside the "app" container: checks that the tools and services that
# Redmine development needs are in place, that Redmine is up, and runs the test
# suites. Pass "--system" to also run the system (E2E) tests.
# .devcontainer/test-redmine.sh calls this through "devcontainer exec".

set -eux

cd "$(dirname "$0")/.."

# Tools.
ruby --version
test "$(ruby -e 'print RUBY_VERSION')" = "$(sed -n 's/^RUBY_VERSION=//p' .devcontainer/.env)"
bundle --version
node --version
yarn --version
git --version
svn --version --quiet
bzr --version
cvs --version
hg --version
chromium --version
chromedriver --version
convert --version | head -n 1
gs --version
claude --version
playwright-mcp --version

# Services. None of them publishes a port to the host; they are reached under
# their service names.
pg_isready --host postgres --username redmine
for address in mysql:3306 redis:6379 mailpit:1025 mailpit:8025 web:3000
do
  ruby -rsocket -e 'host, port = ARGV[0].split(":"); Socket.tcp(host, Integer(port), connect_timeout: 5).close' "${address}"
done

# Sidekiq is the Active Job adapter outside of the test environment.
test "$(bin/rails runner 'print Rails.application.config.active_job.queue_adapter')" = sidekiq

# Git and Subversion are what the repository form offers.
test "$(bin/rails runner 'print Setting.enabled_scm.sort.join(",")')" = 'Git,Subversion'
bin/rails runner 'puts Redmine::Info.environment'

# Redmine, on the "web" service, answers.
for _ in $(seq 60)
do
  curl -fsS -o /dev/null http://web:3000/login && break
  sleep 2
done
curl -fsS http://web:3000/login | grep -q 'id="login-form"'

# An email that Redmine enqueues is delivered by the "sidekiq" service to
# Mailpit.
bin/rails runner '
  user = User.find_by!(login: "admin")
  user.update!(mail: "admin@example.net") if user.mail.blank?
'
before="$(curl -fsS 'http://mailpit:8025/api/v1/messages?limit=1' | ruby -rjson -e 'print JSON.parse($stdin.read)["total"]')"
bin/rails runner 'Mailer.test_email(User.find_by!(login: "admin")).deliver_later'
for _ in $(seq 30)
do
  after="$(curl -fsS 'http://mailpit:8025/api/v1/messages?limit=1' | ruby -rjson -e 'print JSON.parse($stdin.read)["total"]')"
  test "${after}" -gt "${before}" && break
  sleep 1
done
test "${after}" -gt "${before}"

# Playwright MCP drives Chromium to Redmine's login page.
{
  echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"test","version":"0"}}}'
  echo '{"jsonrpc":"2.0","method":"notifications/initialized"}'
  echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"browser_navigate","arguments":{"url":"http://web:3000/login"}}}'
  sleep 30
} | timeout 60 sh -c "$(ruby -rjson -e '
  server = JSON.parse(File.read(".mcp.json"))["mcpServers"]["playwright"]
  print [server["command"], *server["args"]].map { |arg| "\x27#{arg}\x27" }.join(" ")
')" | tee tmp/playwright-mcp-test.log | grep -q 'Page Title: Redmine'

# The test suites, the same ones .github/workflows runs. Some tests, such as
# IssuesControllerTest#test_index_grouped_by_created_on_if_time_zone_is_utc,
# assume the UTC that GitHub Actions runs in, while TZ in the container may
# come from a file in DOT_DEVCONTAINER_HOME.
export TZ=UTC
bin/rails test
LANG=en_US.ISO8859-1 LC_ALL=en_US.ISO8859-1 \
  bin/rails test test/unit/repository_bazaar_test.rb
# Some tests only run on MySQL: those in test/unit/search_test.rb that check
# how MySQL compares accented characters. Run the files holding them against
# the "mysql" service too. DATABASE_URL takes precedence over
# config/database.yml.
#
# The database is built by the migrations rather than from db/schema.rb, which
# PostgreSQL dumped with expression indexes that MySQL does not accept, and
# SCHEMA keeps them from overwriting db/schema.rb with a MySQL dump.
(
  export DATABASE_URL='mysql2://root:redmine@mysql/redmine_test?encoding=utf8mb4'
  export SCHEMA=tmp/test/mysql_schema.rb
  RAILS_ENV=test bin/rails db:drop db:create db:migrate > /dev/null
  bin/rails test $(grep -l -r -E 'skip (unless mysql\?|if .*postgresql\?)' test)
)
bin/rails test:autoload
bundle exec rubocop --parallel
npx stylelint "app/assets/stylesheets/**/*.css"
if test "${1:-}" = --system
then
  bin/rails test:system
fi
