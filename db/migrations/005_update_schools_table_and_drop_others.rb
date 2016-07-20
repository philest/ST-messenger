Sequel.migration do
  up do
    alter_table(:schools) do
      add_column :code, String, default:'read\d+'
      add_column :timezone, String, :default=>"Eastern Time (US & Canada)"
    end

    alter_table(:users) do
      add_foreign_key :school_id, :schools
    end
  end

  down do
    alter_table :users do
      drop_foreign_key :school_id
    end

    alter_table(:schools) do
      drop_column :timezone
      drop_column :code
    end
  end
end