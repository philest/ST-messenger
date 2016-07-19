Sequel.migration do
  up do
    alter_table(:users) do
      drop_column :locale
      add_column :locale, String, default: 'en'
    end

    alter_table(:state_tables) do
      drop_column :story_number
      add_column :story_number, Integer, default: 1
    end

  end

  down do

    alter_table(:state_tables) do
      drop_column :story_number
      add_column :story_number, Integer, default: 0
    end

    alter_table(:users) do
      drop_column :locale
      add_column :locale, String, default: 'en_US'
    end

  end

end