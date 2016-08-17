class User < Sequel::Model(:users)
	plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true
	plugin :validation_helpers
	plugin :association_dependencies
	
	many_to_one :classroom
	many_to_one :teacher
	many_to_one :school
	one_to_many :button_press_logs
	one_to_one :enrollment_queue
	one_to_one :state_table

	add_association_dependencies enrollment_queue: :destroy, button_press_logs: :destroy, state_table: :destroy

	# ensure that user is added EnrollmentQueue upon creation
	def after_create
		super
		# associate an enrollment queue
		eq = EnrollmentQueue.create(user_id: self.id)
		self.enrollment_queue = eq
		eq.user = self
		# associate a state table
		st = StateTable.create(user_id: self.id)
		self.state_table = st
		st.user = self

		# new users on sms need to have a story_number of 0
		if self.platform == 'sms'
			self.state_table.update(story_number: 0)
		end

		# set default curriculum version
		ENV["CURRICULUM_VERSION"] ||= '0'
		self.update(curriculum_version: ENV["CURRICULUM_VERSION"].to_i)
	rescue => e
		p e.message + " could not create and associate a state_table, enrollment_queue, or curriculum_version for this user"
	end

	def validate
    	super
    	validates_unique :phone, :allow_nil=>true, :message => "phone #{phone} is already taken (users)"
    	validates_unique :fb_id, :allow_nil=>true, :message => "fb_id #{fb_id} is already taken (users)"
  	end

end