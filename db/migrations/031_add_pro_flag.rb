Sequel.migration do
  up do
    alter_table(:schools) do
      add_column :plan, String, default: 'pro' # between 'free' and 'pro' at this point
    end
  end
  down do
    alter_table(:schools) do
      drop_column :plan
    end
  end
end
