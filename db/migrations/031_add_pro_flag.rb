Sequel.migration do
  up do
    alter_table(:schools) do
      add_column :pro?, TrueClass, default: false
    end
  end
  down do
    alter_table(:schools) do
      drop_column :pro?
    end
  end
end