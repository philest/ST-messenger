class User < Sequel::Model(:users)
	plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true
	plugin :validation_helpers
	plugin :association_dependencies
	
	many_to_one :teacher
	many_to_one :classroom
	one_to_many :button_press_logs
	one_to_one :enrollment_queue
	one_to_one :state_table

	add_association_dependencies enrollment_queue: :destroy, button_press_logs: :destroy#, #state_table: :destroy

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

		# st = StateTable.create(user_id: self.id)
		# self.state_table = st
		# st.user = self
	end

	def validate
    	super
    	validates_unique :phone, :allow_nil=>true, :message => "phone #{phone} is already taken (users)"
    	validates_unique :fb_id, :allow_nil=>true, :message => "fb_id #{fb_id} is already taken (users)"
  	end

end