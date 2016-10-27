Sequel.migration do
  up do
    alter_table(:teachers) do
      add_column :t_number, Integer, default: 0
    end
  end
  down do
    alter_table(:teachers) do
      drop_column :t_number 
    end
  end
end