Sequel.migration do
	change do
		alter_table(:teachers) do
			add_unique_constraint [:email]
		end
	end
end