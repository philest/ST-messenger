Sequel.migration do
  up do
    alter_table(:users) do
      add_column :reset_password_token_digest, String
    end
  end
  down do
    alter_table(:users) do
      add_column :reset_password_token, String
    end
  end
end