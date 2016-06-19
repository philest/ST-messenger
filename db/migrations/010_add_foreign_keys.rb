Sequel.migration do
	change do
		alter_table(:teachers) do
			add_foreign_key :school_id, :schools
		end
		
		alter_table(:classrooms) do 
			add_foreign_key :teacher_id, :teachers
			add_foreign_key :school_id, :schools
		end

		alter_table(:schools) { add_foreign_key :district_id, :districts }

		alter_table(:school_sessions) { add_foreign_key :school_id, :schools }

		alter_table(:users) do
			add_foreign_key :classroom_id, :classrooms
			add_foreign_key :teacher_id, :teachers
		end
	end
end