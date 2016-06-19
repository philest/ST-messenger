Sequel.migration do 
	change do 
		create_table(:districts) do
		  primary_key :id
		   String :name
		   String :state
		   String :county
		  	Time :created_at
	      Time :updated_at
		end
	end
end