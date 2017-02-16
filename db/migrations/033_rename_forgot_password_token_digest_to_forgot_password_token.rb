Sequel.migration do
  up do
    alter_table(:users) do
      rename_column :reset_password_token_digest, :reset_password_token
    end
  end
  down do
    alter_table(:users) do
      rename_column :reset_password_token, :reset_password_token_digest
    end
  end
end