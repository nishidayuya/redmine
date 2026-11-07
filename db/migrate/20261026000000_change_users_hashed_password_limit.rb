class ChangeUsersHashedPasswordLimit < ActiveRecord::Migration[8.1]
  def up
    # Argon2id hashes in the PHC string format are longer than SHA1 hex digests
    change_column :users, :hashed_password, :string, limit: 255, default: '', null: false
  end

  def down
    change_column :users, :hashed_password, :string, limit: 40, default: '', null: false
  end
end
