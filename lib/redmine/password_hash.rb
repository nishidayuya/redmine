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
  # passwords hashed with any of ALGORITHMS can be verified.
  module PasswordHash
    algorithm_names = [
      # Order of strength
      :argon2id,
      :sha1,
    ]
    ALGORITHMS = algorithm_names.each.with_object({}) do |name, h|
      h[name] = Redmine::PasswordHash.const_get(name.to_s.camelize)
    end
    ALGORITHMS.default_proc = ->(_algorithms, name) do
      raise ArgumentError, "Unsupported password hash algorithm: name=#{name}"
    end

    class << self
      def current_algorithm
        name = Redmine::Configuration['password_hash_algorithm'].presence&.to_sym || :sha1
        ALGORITHMS[name]
      end

      # Returns the algorithm that hashed +hashed_password+, or nil
      def algorithm_for(hashed_password)
        ALGORITHMS.values.find {|algorithm| algorithm.match?(hashed_password)}
      end
    end
  end
end
