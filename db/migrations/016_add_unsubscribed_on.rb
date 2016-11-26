Sequel.migration do
  up do
    alter_table(:state_tables) do
      add_column :unsubscribed_on, DateTime
    end
  end
  down do
    alter_table(:state_tables) do
      drop_column :unsubscribed_on 
    end
  end
end