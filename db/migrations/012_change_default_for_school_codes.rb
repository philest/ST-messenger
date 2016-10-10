Sequel.migration do
  up do
    alter_table(:schools) do
      set_column_default :code, "read|leer"
    end
  end
  down do
    alter_table(:schools) do
      set_column_default :code, "read|leer"
    end
  end
end