Sequel.migration do
  up do
    alter_table(:state_tables) do
      add_column :last_unique_story, Integer, default: 0
      add_column :last_unique_story_read?, TrueClass, default: true
    end
  end
  down do
    alter_table(:state_tables) do
      drop_column :last_unique_story
      drop_column :last_unique_story_read?
    end
  end
end
