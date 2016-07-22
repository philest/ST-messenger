class School < Sequel::Model(:schools)
	plugin :timestamps, :create=>:created_at, :update=>:updated_at, :update_on_create=>true
	plugin :association_dependencies

	one_to_many :teachers
	one_to_many :users
	many_to_one :district
	one_to_many :school_sessions

	add_association_dependencies teachers: :nullify, users: :nullify

end