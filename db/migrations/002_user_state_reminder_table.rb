Sequel.migration do
	up do 
		create_table(:state_tables) do
			primary_key :id
			TrueClass :last_story_read?, default: false
			Time :last_script_sent_time
			String :next_script
			Time :next_story_time
			String :series_name, default: nil 
			Integer :series_index, default: 0 # 0 -> not started series
			Time :last_reminded_time
			Integer :num_reminders, default: 0
			TrueClass :subscribed?, default: true
			Integer :story_number, default: 0
			Time :last_story_read_time
			foreign_key :user_id, :users
			String :last_sequence_seen
			Time :updated_at
		end

		alter_table(:users) do
			add_foreign_key :state_table_id, :state_tables
			add_column :first_name, String
			add_column :last_name, String
			drop_column :name
		end
	end

	down do
		alter_table :users do
			add_column :name, String
			drop_column :last_name
			drop_column :first_name
			drop_foreign_key :state_table_id
		end
		drop_table :state_tables
	end
end