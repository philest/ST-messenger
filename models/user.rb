class User < Sequel::Model(:users)
	plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true
	plugin :validation_helpers
	
	many_to_one :teacher
	many_to_one :classroom

	def validate
    	super
    	validates_unique :phone, :allow_nil=>true, :message => "#{phone} is already taken (users)"
  	end

	# def around_save
	# 	super
	# rescue Java::JavaLang::NoSuchMethodError => e
	# 	p e.message << " - Did not insert user, (probably) already exists in db..."
	# rescue Sequel::UniqueConstraintViolation => e
	# 	p e.message << "\nDid not insert, user already exists in db."
	# rescue Sequel::DatabaseError => e
	# 	p e.message << "\n failure"
	# 	# parse database error, set error on self, and reraise a Sequel::ValidationFailed
	# end

end