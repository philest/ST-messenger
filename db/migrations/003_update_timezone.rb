Sequel.migration do
  change do
    alter_table(:users) do
      drop_column :timezone
      add_column :timezone, String, :default => "Eastern Time (US & Canada)"
    end
  end
end