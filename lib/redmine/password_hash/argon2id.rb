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
  module PasswordHash
    # Stores the PHC string format (e.g. "$argon2id$v=19$m=...") that includes
    # the salt and the parameters, so the salt is left blank
    module Argon2id
      class << self
        def match?(hashed_password)
          hashed_password.to_s.start_with?('$argon2id$')
        end

        def digest_password(clear_password)
          [nil, ::Argon2id::Password.create(clear_password.to_s).to_s]
        end

        def verify_password(clear_password, salt, hashed_password)
          ::Argon2id::Password.new(hashed_password).is_password?(clear_password.to_s)
        rescue ArgumentError, ::Argon2id::Error
          false
        end
      end
    end
  end
end
