Sequel.migration do
  up do
    alter_table(:teachers) do
      rename_column :password, :password_digest
    end

    alter_table(:admins) do
      rename_column :password, :password_digest
    end
  end
  down do
    alter_table(:teachers) do
      rename_column :password_digest, :password
    end

    alter_table(:admins) do
      rename_column :password_digest, :password
    end
  end
end