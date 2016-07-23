Sequel.migration do
  up do
    alter_table(:users) do
      add_column :platform, String, default: 'fb'
    end
  end
  down do
    alter_table(:users) do
      drop_column :platform
    end
  end
end