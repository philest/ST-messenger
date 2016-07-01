class StateTable < Sequel::Model(:state_tables)
	plugin :timestamps, :update=>:updated_at, :update_on_create=>true
	plugin :validation_helpers
	plugin :association_dependencies
	
	one_to_one :user
	
	add_association_dependencies user: :nullify

	# def before_destroy
	# 	super
	# 	update(enrollment_queue_id: nil)
	# 	enrollment_queue = nil
	# end

	# ensure that user is added EnrollmentQueue upon creation
	def after_create
		super
		eq = EnrollmentQueue.create(user_id: self.id)
		self.enrollment_queue = eq
		eq.user = self		
	end

	def validate
    	super
    	validates_unique :phone, :allow_nil=>true, :message => "phone #{phone} is already taken (users)"
    	validates_unique :fb_id, :allow_nil=>true, :message => "fb_id #{fb_id} is already taken (users)"
  	end

end