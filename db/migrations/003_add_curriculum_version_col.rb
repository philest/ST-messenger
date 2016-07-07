Sequel.migration do
	up do
		alter_table(:users) do
			add_column :curriculum_version, Integer, default: 0
		end
	end

	down do
		alter_table(:users) do
			drop_column :curriculum_version
		end
	end

end