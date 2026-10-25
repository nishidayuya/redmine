# frozen_string_literal: true

# Additional configuration for the Dev Container in .devcontainer. This file is
# instance_eval'd by config/application.rb, where "config" is the configuration
# of the Rails application.

# Background jobs run on Sidekiq: the "sidekiq" service of
# .devcontainer/docker-compose.yml works them off, and both sides reach the
# "redis" service through REDIS_URL.
#
# The test environment is left alone: config/environments/test.rb picks the
# :inline adapter, which is what the test suite expects.
config.active_job.queue_adapter = :sidekiq unless Rails.env.test?

# Redmine runs on http://web:3000 inside the Compose network, and Rails only
# accepts localhost and IP addresses as the host name in development.
config.hosts << 'web' if Rails.env.development?
