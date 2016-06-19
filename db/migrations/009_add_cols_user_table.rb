Sequel.migration do 
	change do
		alter_table(:users) do
		  add_column :child_age, Integer
		  add_column :child_name, String
		  add_column :reading_level, Integer, :default => 0
		  add_column :gender, String
		  # add_foreign_key :classroom_id, :classrooms
		  # add_foreign_key :teacher_id, :teachers
		end
	end
end