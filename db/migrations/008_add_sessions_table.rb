Sequel.migration do 
	change do
		create_table(:school_sessions) do
		  primary_key :id
		   # foreign_key :school_id, :schools
		   String :session_type
		   Time :start_date
		   Time :end_date
		   Time :created_at
	      Time :updated_at
		end
	end
end