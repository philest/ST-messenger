Sequel.migration do
  up do
    alter_table(:schools) do
      add_column :signature, String
    end
  end
  down do
    alter_table(:schools) do
      drop_column :signature 
    end
  end
end