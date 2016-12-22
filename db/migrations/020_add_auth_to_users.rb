Sequel.migration do
  up do
    alter_table(:users) do
      add_column :password_digest, String # how do we make this a required field?
      add_column :email, String, unique: true # the user must have a phone# OR email OR both
      add_column :refresh_token_digest, String
    end
  end
  down do
    alter_table(:users) do
      drop_column :password_digest
      drop_column :email
      drop_column :refresh_token_digest
    end
  end
end