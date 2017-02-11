# require 'createsend'
require 'sidekiq'
require 'dotenv'
Dotenv.load if ['development', 'test'].include? ENV['RACK_ENV']


class NotifyAdminWorker
  include Sidekiq::Worker

  sidekiq_options :retry => false # job will be discarded immediately if failed

  def new_teachers_notification(admin)
    last_notified = admin.notified_on.nil? ? admin.enrolled_on : admin.notified_on

    # all teachers should have a signature, so......
    teachers = Teacher.where(school: admin.school).where{enrolled_on > last_notified}.all
    count = teachers.size

    sing_or_plural = count > 1 ? 'teachers' : 'teacher'
    quicklink = admin.quicklink


    if count == 0
      puts "no new teachers signed up"
      return
    end

    if count > 0
      if count == 1
        list_o_names = teachers.first.signature

      elsif count == 2
          list_o_names = teachers.first.signature
          list_o_names += " and #{teachers.last.signature}"

      else
        last_teacher = teachers.pop
        list_o_names = teachers.inject('') do |string, teacher|
          str = teacher.signature.to_s
          str += ", "
          string += str
        end

        last_u_name = last_teacher.signature

        list_o_names += "and #{last_u_name}"

      end
    else # we only have teachers users...
      list_o_names = "See who"
    end # if named.size > 0

    puts admin.first_name, admin.email, count, sing_or_plural, list_o_names, quicklink

    new_teachers_notification_helper(admin.first_name, admin.email, count, sing_or_plural, list_o_names, quicklink)
  end

  def new_teachers_notification_helper(sig, email, count, teacher_or_teachers, list_o_names, quicklink)
    HTTParty.post(
      ENV['STORYTIME_URL'] + '/enroll/update_admin',
      body: {
        sig: sig,
        email: email,
        count: count,
        teacher_or_teachers: teacher_or_teachers,
        list_o_names: list_o_names,
        quicklink: quicklink
      }
    )

  end

  def perform(admin_id)
    admin = Admin.where(id: admin_id).first
    if admin.nil?
      return
    end

    new_teachers_notification(admin)

    admin.update(notified_on: Time.now.utc)

  end # perform

end


class NotifyTeacherWorker
  include Sidekiq::Worker

  sidekiq_options :retry => false # job will be discarded immediately if failed

  def new_users_notification(teacher)

    last_notified = teacher.notified_on.nil? ? teacher.enrolled_on : teacher.notified_on

    named = User.where(teacher: teacher,role:'parent').where{enrolled_on > last_notified}.exclude(first_name: nil).all
    unnamed = User.where(teacher: teacher,role:'parent').where{enrolled_on > last_notified}.where(first_name: nil).all
    count = named.size + unnamed.size
    family = count > 1 ? 'families' : 'family'
    quicklink = teacher.quicklink


    if count == 0
      puts "no new users signed up"
      return
    end



    if named.size > 0
      if named.size == 1
        list_o_names = named.first.first_name
        list_o_names += " #{named.first.last_name.to_s}" if not named.first.last_name.nil?

        if unnamed.size > 0
          list_o_names += " and #{unnamed.size} other#{unnamed.size > 1 ? 's' : ''}"
        end

      elsif named.size == 2

        if unnamed.size > 0
          list_o_names = named.first.first_name
          list_o_names += " #{named.first.last_name.to_s}" if not named.first.last_name.nil?
          list_o_names += ", #{named.last.first_name}"
          list_o_names += " #{named.last.last_name.to_s}" if not named.last.last_name.nil?
          list_o_names += ", and #{unnamed.size} other#{unnamed.size > 1 ? 's' : ''}"
        else
          list_o_names = named.first.first_name
          list_o_names += " #{named.first.last_name.to_s}" if not named.first.last_name.nil?
          list_o_names += " and #{named.last.first_name}"
          list_o_names += " #{named.last.last_name.to_s}" if not named.last.last_name.nil?
        end

      else
        last_user = named.pop
        list_o_names = named.inject('') do |string, user|
          str = user.first_name.to_s
          str += " #{user.last_name.to_s}" if not user.last_name.nil?
          str += ", "
          string += str
        end

        last_u_name = last_user.first_name
        last_u_name += " #{last_user.last_name.to_s}" if not last_user.last_name.nil?

        if unnamed.size > 0
          list_o_names += "#{last_u_name}, and #{unnamed.size} other#{unnamed.size > 1 ? 's' : ''}"
        else
          list_o_names += "and #{last_u_name}"
        end

      end
    else # we only have unnamed users...
      list_o_names = "See who"
    end # if named.size > 0

    puts "sending email to #{teacher.signature}, #{teacher.email}, #{count}, #{family}, #{list_o_names}, #{quicklink}"


    new_users_notification_helper(teacher.signature, teacher.email, count, family, list_o_names, quicklink)
  end

  def new_users_notification_helper(sig, email, count, family, list_o_names, quicklink)
    HTTParty.post(
      ENV['STORYTIME_URL'] + '/enroll/update_teacher',
      body: {
        sig: sig,
        email: email,
        count: count,
        family: family,
        list_o_names: list_o_names,
        quicklink: quicklink
      }
    )

  end

  def perform(teacher_id)

    teacher = Teacher.where(id: teacher_id).first

    if teacher.nil?
      puts "teacher with id #{teacher_id} doesn't exist"
      return
    end

    new_users_notification(teacher)


    teacher.update(notified_on: Time.now.utc)

  end # perform


end












