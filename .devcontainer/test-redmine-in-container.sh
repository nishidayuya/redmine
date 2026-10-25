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

# The test suites, the same ones .github/workflows runs.
bin/rails test
bin/rails test:autoload
bundle exec rubocop --parallel
npx stylelint "app/assets/stylesheets/**/*.css"
if test "${1:-}" = --system
then
  bin/rails test:system
fi
