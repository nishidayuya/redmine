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
  def test_algorithms
    assert_equal(
      {argon2id: Redmine::PasswordHash::Argon2id, sha1: Redmine::PasswordHash::Sha1},
      Redmine::PasswordHash::ALGORITHMS
    )
  end

  def test_sha1
    salt, hashed_password = Redmine::PasswordHash::Sha1.digest_password('hello123')

    assert_match /\A\h{32}\z/, salt
    assert Redmine::PasswordHash::Sha1.match?(hashed_password)
    assert_not Redmine::PasswordHash::Argon2id.match?(hashed_password)
    assert Redmine::PasswordHash::Sha1.verify_password('hello123', salt, hashed_password)
    assert_not Redmine::PasswordHash::Sha1.verify_password('hello124', salt, hashed_password)
  end

  def test_argon2id
    salt, hashed_password = Redmine::PasswordHash::Argon2id.digest_password('hello123')

    assert_nil salt
    assert Redmine::PasswordHash::Argon2id.match?(hashed_password)
    assert_not Redmine::PasswordHash::Sha1.match?(hashed_password)
    assert Redmine::PasswordHash::Argon2id.verify_password('hello123', nil, hashed_password)
    assert_not Redmine::PasswordHash::Argon2id.verify_password('hello124', nil, hashed_password)
  end

  def test_argon2id_verify_password_should_return_false_with_broken_hash
    assert_not Redmine::PasswordHash::Argon2id.verify_password('hello123', nil, '$argon2id$broken')
  end

  def test_current_algorithm_should_return_configured_algorithm
    with_password_hash_algorithm 'sha1' do
      assert_equal Redmine::PasswordHash::Sha1, Redmine::PasswordHash.current_algorithm
    end
    with_password_hash_algorithm 'argon2id' do
      assert_equal Redmine::PasswordHash::Argon2id, Redmine::PasswordHash.current_algorithm
    end
  end

  def test_current_algorithm_should_return_sha1_by_default
    with_password_hash_algorithm nil do
      assert_equal Redmine::PasswordHash::Sha1, Redmine::PasswordHash.current_algorithm
    end
  end

  def test_current_algorithm_should_raise_error_with_unsupported_algorithm
    with_password_hash_algorithm 'md5' do
      error = assert_raise ArgumentError do
        Redmine::PasswordHash.current_algorithm
      end
      assert_equal 'Unsupported password hash algorithm: name=md5', error.message
    end
  end

  def test_algorithm_for
    _, sha1 = Redmine::PasswordHash::Sha1.digest_password('hello123')
    _, argon2id = Redmine::PasswordHash::Argon2id.digest_password('hello123')

    %w[sha1 argon2id].each do |name|
      with_password_hash_algorithm name do
        assert_equal Redmine::PasswordHash::Sha1, Redmine::PasswordHash.algorithm_for(sha1)
        assert_equal Redmine::PasswordHash::Argon2id, Redmine::PasswordHash.algorithm_for(argon2id)
      end
    end
  end

  def test_algorithm_for_should_return_nil_with_unknown_hash
    assert_nil Redmine::PasswordHash.algorithm_for('')
    assert_nil Redmine::PasswordHash.algorithm_for(nil)
    assert_nil Redmine::PasswordHash.algorithm_for('$2a$12$unknown')
  end

  private

  def with_password_hash_algorithm(name, &)
    Redmine::Configuration.with('password_hash_algorithm' => name, &)
  end
end
