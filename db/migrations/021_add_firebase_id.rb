Sequel.migration do
  up do
    alter_table(:users) do
      add_column :firebase_id, String, unique:true # how do we make this a required field?
    end
  end
  down do
    alter_table(:users) do
      drop_column :firebase_id
    end
  end
end