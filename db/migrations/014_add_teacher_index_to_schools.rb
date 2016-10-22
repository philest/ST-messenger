Sequel.migration do
  up do
    alter_table(:schools) do
      add_column :teacher_index, Integer, default: 0
    end
  end
  down do
    alter_table(:schools) do
      drop_column :teacher_index
    end
  end
end