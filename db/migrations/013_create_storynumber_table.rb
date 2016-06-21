Sequel.migrations do
	change do
		alter_table(:users) do
			drop_column :story_number
		end

		create_table(:story_number)
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