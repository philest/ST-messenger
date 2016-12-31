Sequel.migration do
  up do
    alter_table(:users) do
      add_column :role, String, default: 'parent'
    end
  end
  down do
    alter_table(:users) do
      drop_column :role 
    end
  end
end