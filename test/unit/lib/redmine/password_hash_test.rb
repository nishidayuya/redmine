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
  fixtures :users

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

  def test_digest_password_should_use_configured_algorithm
    with_password_hash_algorithm 'sha1' do
      assert Redmine::PasswordHash::Sha1.match?(Redmine::PasswordHash.digest_password('hello123').last)
    end
    with_password_hash_algorithm 'argon2id' do
      assert Redmine::PasswordHash::Argon2id.match?(Redmine::PasswordHash.digest_password('hello123').last)
    end
  end

  def test_digest_password_should_use_sha1_by_default
    with_password_hash_algorithm nil do
      assert Redmine::PasswordHash::Sha1.match?(Redmine::PasswordHash.digest_password('hello123').last)
    end
  end

  def test_digest_password_should_raise_error_with_unsupported_algorithm
    with_password_hash_algorithm 'md5' do
      assert_raise ArgumentError do
        Redmine::PasswordHash.digest_password('hello123')
      end
    end
  end

  def test_verify_password_should_verify_any_algorithm
    sha1 = Redmine::PasswordHash::Sha1.digest_password('hello123')
    argon2id = Redmine::PasswordHash::Argon2id.digest_password('hello123')

    %w[sha1 argon2id].each do |name|
      with_password_hash_algorithm name do
        assert Redmine::PasswordHash.verify_password('hello123', *sha1)
        assert Redmine::PasswordHash.verify_password('hello123', *argon2id)
        assert_not Redmine::PasswordHash.verify_password('hello124', *sha1)
        assert_not Redmine::PasswordHash.verify_password('hello124', *argon2id)
      end
    end
  end

  def test_verify_password_should_return_false_with_unknown_hash
    assert_not Redmine::PasswordHash.verify_password('', nil, '')
    assert_not Redmine::PasswordHash.verify_password('hello123', nil, '$2a$12$unknown')
  end

  def test_outdated
    user = User.find(1)

    with_password_hash_algorithm 'sha1' do
      assert_not Redmine::PasswordHash.outdated?(user)
    end
    with_password_hash_algorithm 'argon2id' do
      assert Redmine::PasswordHash.outdated?(user)
    end
  end

  def test_outdated_should_return_false_without_hashed_password
    user = User.find(1)
    user.hashed_password = ''

    with_password_hash_algorithm 'argon2id' do
      assert_not Redmine::PasswordHash.outdated?(user)
    end
  end

  def test_outdated_should_return_false_with_auth_source
    user = User.find(1)
    user.auth_source_id = 1

    with_password_hash_algorithm 'argon2id' do
      assert_not Redmine::PasswordHash.outdated?(user)
    end
  end

  private

  def with_password_hash_algorithm(name, &)
    Redmine::Configuration.with('password_hash_algorithm' => name, &)
  end
end
