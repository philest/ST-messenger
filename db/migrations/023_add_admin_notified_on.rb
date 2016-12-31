Sequel.migration do
  up do
    alter_table(:admins) do
      add_column :notified_on, DateTime
    end
  end
  down do
    alter_table(:admins) do
      drop_column :notified_on 
    end
  end
end