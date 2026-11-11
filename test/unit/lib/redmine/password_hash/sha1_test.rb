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

class Redmine::PasswordHash::Sha1Test < ActiveSupport::TestCase
  def test_digest_password
    salt, hashed_password = Redmine::PasswordHash::Sha1.digest_password('hello123')

    assert_match /\A\h{32}\z/, salt
    assert_match /\A\h{40}\z/, hashed_password
  end

  def test_match
    _, hashed_password = Redmine::PasswordHash::Sha1.digest_password('hello123')
    _, argon2id = Redmine::PasswordHash::Argon2id.digest_password('hello123')

    assert Redmine::PasswordHash::Sha1.match?(hashed_password)
    assert_not Redmine::PasswordHash::Sha1.match?(argon2id)
    assert_not Redmine::PasswordHash::Sha1.match?('')
    assert_not Redmine::PasswordHash::Sha1.match?(nil)
  end

  def test_verify_password
    salt, hashed_password = Redmine::PasswordHash::Sha1.digest_password('hello123')

    assert Redmine::PasswordHash::Sha1.verify_password('hello123', salt, hashed_password)
    assert_not Redmine::PasswordHash::Sha1.verify_password('hello124', salt, hashed_password)
  end
end
