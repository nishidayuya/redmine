# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module Redmine
  # Hashes and verifies the passwords of the users authenticated by Redmine
  # itself. New passwords are hashed with the algorithm given by the
  # password_hash_algorithm setting of config/configuration.yml, and
  # passwords hashed with any of ALGORITHM_NAMES can be verified.
  module PasswordHash
    # Order of strength
    ALGORITHM_NAMES = %w[
      argon2id
      sha1
    ].freeze

    class << self
      # Returns true if the password of +user+ was not hashed with the
      # configured algorithm
      def outdated?(user)
        return false if user.auth_source_id.present? || user.hashed_password.blank?

        !current_algorithm.match?(user.hashed_password)
      end

      # Returns [salt, hashed_password] for +clear_password+
      def digest_password(clear_password)
        current_algorithm.digest_password(clear_password)
      end

      # Returns true if +clear_password+ matches +hashed_password+, whatever
      # algorithm hashed it
      def verify_password(clear_password, salt, hashed_password)
        algorithm = algorithm_for(hashed_password)
        return false unless algorithm

        algorithm.verify_password(clear_password, salt, hashed_password)
      end

      private

      def current_algorithm_name
        name = Redmine::Configuration['password_hash_algorithm'].to_s.downcase.presence || 'sha1'
        raise ArgumentError, "Unsupported password_hash_algorithm: #{name}" unless ALGORITHM_NAMES.include?(name)

        name
      end

      def current_algorithm
        algorithm(current_algorithm_name)
      end

      def algorithm(name)
        Redmine::PasswordHash.const_get(name.camelize)
      end

      # Returns the algorithm that hashed +hashed_password+, or nil
      def algorithm_for(hashed_password)
        ALGORITHM_NAMES.map {|name| algorithm(name)}.find {|a| a.match?(hashed_password)}
      end
    end
  end
end
