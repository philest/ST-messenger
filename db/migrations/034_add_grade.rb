Sequel.migration do
  up do
    alter_table(:teachers) do
      add_column :grade, String
    end

    alter_table(:admins) do
      add_column :grade, String
    end
  end
  down do
    alter_table(:teachers) do
      drop_column :grade
    end

    alter_table(:admins) do
      drop_column :grade
    end
  end
end