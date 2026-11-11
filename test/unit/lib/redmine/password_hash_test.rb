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

require_relative '../../../test_helper'

class Redmine::PasswordHashTest < ActiveSupport::TestCase
  def test_s_current_algorithm_should_return_configured_algorithm
    with_password_hash_algorithm :sha1 do
      assert_equal Redmine::PasswordHash::Sha1, Redmine::PasswordHash.current_algorithm
    end
    with_password_hash_algorithm :argon2id do
      assert_equal Redmine::PasswordHash::Argon2id, Redmine::PasswordHash.current_algorithm
    end
  end

  def test_s_current_algorithm_should_return_sha1_by_default
    with_password_hash_algorithm nil do
      assert_equal Redmine::PasswordHash::Sha1, Redmine::PasswordHash.current_algorithm
    end
  end

  def test_s_current_algorithm_should_raise_error_with_unsupported_algorithm
    with_password_hash_algorithm :md5 do
      error = assert_raise ArgumentError do
        Redmine::PasswordHash.current_algorithm
      end
      assert_equal 'Unsupported password hash algorithm: name=md5', error.message
    end
  end

  def test_s_algorithm_for
    _, sha1 = Redmine::PasswordHash::Sha1.digest_password('hello123')
    _, argon2id = Redmine::PasswordHash::Argon2id.digest_password('hello123')

    [:sha1, :argon2id].each do |name|
      with_password_hash_algorithm name do
        assert_equal Redmine::PasswordHash::Sha1, Redmine::PasswordHash.algorithm_for(sha1)
        assert_equal Redmine::PasswordHash::Argon2id, Redmine::PasswordHash.algorithm_for(argon2id)
      end
    end
  end

  def test_s_algorithm_for_should_return_nil_with_unknown_hash
    assert_nil Redmine::PasswordHash.algorithm_for('')
    assert_nil Redmine::PasswordHash.algorithm_for(nil)
    assert_nil Redmine::PasswordHash.algorithm_for('$2a$12$unknown')
  end
end
