Sequel.migration do
  up do
    alter_table(:schools) do
      add_column :city, String
      add_column :state, String
    end
  end
  down do
    alter_table(:schools) do
      drop_column :state
      drop_column :city
    end
  end
end