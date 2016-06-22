Sequel.migration do
	change do
		alter_table(:users) do
			add_column :profile_pic, String
		end
	end
end