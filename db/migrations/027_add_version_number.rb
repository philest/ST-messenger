Sequel.migration do
  up do
    alter_table(:users) do
      add_column :app_version_number, Integer
    end
  end
  down do
    alter_table(:users) do
      drop_column :app_version_number
    end
  end
end