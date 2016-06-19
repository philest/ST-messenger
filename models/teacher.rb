class Teacher < Sequel::Model(:teachers)
	plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true

	many_to_one :school
	one_to_many :classrooms
	one_to_many :users

end