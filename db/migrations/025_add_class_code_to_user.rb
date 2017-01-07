Sequel.migration do
  up do
    alter_table(:users) do
      add_column :class_code, String
    end
  end
  down do
    alter_table(:users) do
      drop_column :class_code, String
    end
  end
end