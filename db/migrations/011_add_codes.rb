Sequel.migration do
  up do
    alter_table(:teachers) do
      add_column :code, String
    end

    alter_table(:users) do
      add_column :code, String
    end
  end
  down do
    alter_table(:users) do
      drop_column :code
    end

    alter_table(:teachers) do
      drop_column :code
    end
  end
end