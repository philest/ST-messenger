Sequel.migration do
  up do
    alter_table(:teachers) do
      add_column :propic, String
    end
  end
  down do
    alter_table(:teachers) do
      drop_column :propic
    end
  end
end