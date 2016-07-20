class Teacher < Sequel::Model(:teachers)
	plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true
	plugin :validation_helpers
	plugin :association_dependencies

	many_to_one :school
	one_to_many :classrooms
	one_to_many :users

	add_association_dependencies users: :nullify


	def validate
    	super
    	validates_unique :phone, :allow_nil=>true, :message => "phone #{phone} is already taken (teachers)"
    	validates_unique :email, :allow_nil=>true, :message => "email #{email} is already taken (teachers)"
    	validates_unique :fb_id, :allow_nil=>true, :message => "fb_id #{fb_id} is already taken (teachers)"
  	end

end