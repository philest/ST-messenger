Sequel.migration do
  up do
    alter_table(:schools) do
      add_column :total_users, Integer
    end
  end
  down do
    alter_table(:schools) do
      drop_column :total_users
    end
  end
end