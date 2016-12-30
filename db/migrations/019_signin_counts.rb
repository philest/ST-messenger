Sequel.migration do
  up do
    alter_table(:admins) do
      add_column :signin_count, Integer, default: 0
    end

    alter_table(:teachers) do
      add_column :signin_count, Integer, default: 0
    end

  end
  
  down do
    alter_table(:admins) do
      drop_column :signin_count
    end

    alter_table(:teachers) do
      drop_column :signin_count
    end

  end
end