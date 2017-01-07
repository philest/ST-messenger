Sequel.migration do
  up do
    alter_table(:users) do
      drop_column :firebase_id
      add_column :fcm_token, String
    end
  end
  down do
    alter_table(:users) do
      add_column :firebase_id, String
      drop_column :fcm_token
    end
  end
end