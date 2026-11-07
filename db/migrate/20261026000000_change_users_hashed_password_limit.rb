class ChangeUsersHashedPasswordLimit < ActiveRecord::Migration[8.1]
  def up
    # Argon2id hashes in the PHC string format are longer than SHA1 hex digests
    change_column :users, :hashed_password, :string, limit: 255, default: '', null: false
  end

  def down
    # Argon2id hashes do not fit in 40 characters
    count = User.where('hashed_password LIKE ?', '$argon2id$%').count
    if count > 0
      raise ActiveRecord::IrreversibleMigration,
            "#{count} user(s) have passwords hashed with Argon2id, reset them with SHA1 first"
    end

    change_column :users, :hashed_password, :string, limit: 40, default: '', null: false
  end
end
