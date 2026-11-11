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
require_relative '../../../../test_helper'

class Redmine::PasswordHash::Argon2idTest < ActiveSupport::TestCase
  def test_digest_password
    salt, hashed_password = Redmine::PasswordHash::Argon2id.digest_password('hello123')

    assert_nil salt
    assert hashed_password.start_with?('$argon2id$')
  end

  def test_match
    _, hashed_password = Redmine::PasswordHash::Argon2id.digest_password('hello123')
    _, sha1 = Redmine::PasswordHash::Sha1.digest_password('hello123')

    assert Redmine::PasswordHash::Argon2id.match?(hashed_password)
    assert_not Redmine::PasswordHash::Argon2id.match?(sha1)
    assert_not Redmine::PasswordHash::Argon2id.match?('')
    assert_not Redmine::PasswordHash::Argon2id.match?(nil)
  end

  def test_verify_password
    _, hashed_password = Redmine::PasswordHash::Argon2id.digest_password('hello123')

    assert Redmine::PasswordHash::Argon2id.verify_password('hello123', nil, hashed_password)
    assert_not Redmine::PasswordHash::Argon2id.verify_password('hello124', nil, hashed_password)
  end

  def test_verify_password_should_return_false_with_broken_hash
    assert_not Redmine::PasswordHash::Argon2id.verify_password('hello123', nil, '$argon2id$broken')
  end
end
