class Classroom < Sequel::Model(:classrooms)
	plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true

	many_to_one :teachers
	many_to_one :schools
	one_to_many :users

end