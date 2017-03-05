Sequel.migration do
  up do
    alter_table(:users) do
      drop_column :last_refresh_token_iss
      add_column :last_refresh_token_iss, DateTime, default: DateTime.parse("1995-07-11T23:00:00.000000000+0000")
    end
  end
  down do
    alter_table(:users) do
      drop_column :last_refresh_token_iss
      add_column :last_refresh_token_iss, DateTime, default: DateTime.parse("2017-02-01T23:00:00.000000000+0000")
    end
  end
end