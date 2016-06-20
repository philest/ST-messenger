Sequel.migration do
	change do
		alter_table(:users) do
			drop_column :story_number
			add_column :story_number, Integer, :default => 1
		end
	end
end