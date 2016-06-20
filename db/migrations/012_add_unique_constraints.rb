Sequel.migration do
	change do
		alter_table(:teachers) do
			add_unique_constraint [:email]
			add_column :prefix, String
			add_column :signature, String 
		end
	end
end