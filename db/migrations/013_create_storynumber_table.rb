Sequel.migration do
	change do
		create_table(:button_press_logs) do
			primary_key :id
			Time :created_at
			Integer :day_number
			String :sequence_name
			foreign_key :user_id, :users
			index [:day_number, :sequence_name]
		end
	end
end

# automatically add story_number row which associates w/ user, default = 1
# automatically delete corresponding story_number row after deleting user
# 
# button_press_logs table
# user_id foreign key
# timestamp
# day_number Integer
# sequence String
# 
# 