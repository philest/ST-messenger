class Admin < Sequel::Model(:admins)
  plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true
  plugin :validation_helpers
  plugin :association_dependencies
  plugin :json_serializer

  many_to_one :school

  def quicklink
    "http://www.joinstorytime.com/signin?email=#{email}&name=#{signature.split(' ').join('+')}&school=#{self.school.code.split('|')[0]}&role=admin"
  end

  def validate
    super
    validates_unique :phone, :allow_nil=>true, :message => "#{phone} is already taken (admin)"
    validates_unique :email, :allow_nil=>true, :message => "#{email} is already taken (admin)"
  end

end