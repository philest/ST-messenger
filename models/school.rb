class School < Sequel::Model(:schools)
	plugin :timestamps, :create=>:created_at, :update=>:updated_at, :update_on_create=>true
	plugin :association_dependencies
  plugin :json_serializer

	one_to_many :teachers
	one_to_many :users
	many_to_one :district
	one_to_many :school_sessions

	add_association_dependencies teachers: :nullify, users: :nullify

  def signup_teacher(teacher)
    if self.teachers.select {|t| t.id == teacher.id }.size == 0
      teacher_i = self.teacher_index + 1
      self.update(teacher_index: teacher_i)
      code = self.code.split('|').map{|c| "#{c}#{self.teacher_index}" }.join('|')
      teacher.update(code: code)
      teacher.update(t_number: teacher_i)
      self.add_teacher(teacher)
    else
      puts "Teacher #{teacher.signature} is already associated with #{self.signature}"
    end
  end
end