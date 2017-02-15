module SIGNUP

  def self.create_user(user_constructor, phone, first_name, last_name, password, class_code, platform, role, time_zone = nil)

    userData = {
      phone: phone,
      first_name: first_name.strip,
      last_name: last_name.strip,
      class_code: class_code,
      platform: platform,
      role: role,
    }

    if (time_zone) then
      userData['tz_offset'] = time_zone
    end

    return user_constructor.create(userData)

  end


	def self.register_user(db_user, class_code, password, story_number, last_unique_story_number, last_story_read)
      db_user.set_password(password)
      init_state_table = {
        story_number: story_number,
        subscribed?: true,
        last_story_read?: true,
        last_unique_story: last_unique_story_number
      }
      db_user.state_table.update(init_state_table)
      # associate school/teacher, whichever
      db_user.match_school(class_code)
      db_user.match_teacher(class_code)
	end

  def self.create_free_agent_school(schoolRef, teacherRef, school_code)
    school_name = 'Free Agent School'
    school_sig  = 'StoryTime'

    teacher_name = "#{school_name} Teacher"
    teacher_sig  = school_sig
    davids_email = 'david@joinstorytime.com'

    default_school = schoolRef.where(name: school_name).first

    begin

      if (!default_school)
        default_school = schoolRef.create(
          signature: school_sig,
          name: school_name,
          code: school_code,
          plan: 'free'
        )
      end

    rescue Exception => e # TODO, better error handling
      # TODO: throw this error instead of printing?...
      puts "ERROR: Could not create free agent school ["
      puts e
      puts "]"
      raise e # TODO: make this error more specific

    end

    begin

      default_teacher = teacherRef.where(name: teacher_name).first
      if (!default_teacher)
        default_teacher = teacherRef.create(
          signature: teacher_sig,
          name: teacher_name,
          email: davids_email,
        )
        default_school.signup_teacher(default_teacher)
      end

    rescue Exception => e # TODO, better error handling

      puts "ERROR: Could not create free agent teacher ["
      puts e
      puts "]"
      raise e

    end

    return [default_teacher, default_school]

  end

end