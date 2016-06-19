class School < Sequel::Model(:schools)
	plugin :timestamps, :create=>:created_at, :update=>:updated_at, :update_on_create=>true

	one_to_many :teachers
	many_to_one :districts

end