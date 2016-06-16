Sequel.migration do
  change do
    alter_table(:users) do
      add_column :created_at, DateTime, :default => DateTime.now
    end
  end
end
