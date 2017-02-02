Sequel.migration do
  up do
    alter_table(:teachers) do
      add_column :first_name, String
      add_column :last_name, String
    end
  end
  down do
    alter_table(:teachers) do
      drop_column :last_name
      drop_column :first_name
    end
  end
end