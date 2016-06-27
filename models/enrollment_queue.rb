class EnrollmentQueue < Sequel::Model(:enrollment_queue)
	plugin :timestamps, :create=>:created_at, :update=>:updated_at, :update_on_create=>true
	one_to_one :user
end