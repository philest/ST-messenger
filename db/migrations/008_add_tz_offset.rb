Sequel.migration do
  up do
    alter_table(:users) do
      add_column :tz_offset, Integer, default: -4
    end
  end
  down do
    alter_table(:users) do
      drop_column :tz_offset
    end
  end
end