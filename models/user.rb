class User < Sequel::Model(:users)
	plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true
	plugin :validation_helpers
	
	many_to_one :teacher
	many_to_one :classroom
	one_to_many :button_press_logs
	one_to_one :enrollment_queue 


	def before_destroy
		super
		# clean your room, mister!
		ButtonPressLog.where(user_id: self.id).delete
		EnrollmentQueue.where(user_id: self.id).delete
	end

	def after_create
		super
		eq = EnrollmentQueue.create(user_id: self.id)
		self.enrollment_queue = eq
		eq.user = self
		
	end

	def validate
    	super
    	validates_unique :phone, :allow_nil=>true, :message => "#{phone} is already taken (users)"
  	end

end