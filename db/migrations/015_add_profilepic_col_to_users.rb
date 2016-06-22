Sequel.migration do
	up do
		alter_table(:users) do
			add_column :profile_pic, String
		end
	end

	down do
		alter_table(:users) do
			drop_column :profile_pic
		end
	end
end