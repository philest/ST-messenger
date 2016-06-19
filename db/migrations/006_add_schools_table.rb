Sequel.migration do 
	change do
		create_table(:schools) do
			primary_key :id
		   String :name
		   # foreign_key :district_id, :districts
		   String :zip_code
		   String :address
		   String :phone
		   String :email
		   Time :created_at
		  Time :updated_at
		end
	end
end