Sequel.migration do
  up do
    alter_table(:state_tables) do
      set_column_default :story_number, 0
    end
  end
  down do
    alter_table(:state_tables) do
      set_column_default :story_number, 1
    end
  end
end