class User < Sequel::Model(:users)
	plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true
	plugin :validation_helpers
	
	many_to_one :teacher
	many_to_one :classroom
	one_to_many :button_press_logs
	one_to_one :enrollment_queue

	def validate
    	super
    	validates_unique :phone, :allow_nil=>true, :message => "#{phone} is already taken (users)"
  	end

end