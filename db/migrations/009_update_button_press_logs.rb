Sequel.migration do
  up do
    alter_table(:button_press_logs) do
      add_column :platform, String, default: 'fb'
      add_column :script_name, String
    end
  end
  down do
    alter_table(:button_press_logs) do
      drop_column :script_name
      drop_column :platform
    end
  end
end