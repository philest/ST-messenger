Sequel.migration do 
	change do
		create_table(:classrooms) do
		  primary_key :id
		  # foreign_key :teacher_id, :teachers
		  # foreign_key :school_id, :schools
		  Time :enrolled_on
	      Time :updated_at
		end
	end
end