module NameCodes

  def self.included(base)
    base.extend(self)
  end

  def teacher_school_messaging(trans_stub, recipient) # for translation stub? first thing i thought of
      if (/_+poc_+/i).match(trans_stub).nil? # if no match, just return the original stub
        return trans_stub
      end

      if recipient.is_a? User
        user = recipient
      else
        user = User.where(phone: recipient).first
        if user.nil? # try facebook
          user = User.where(fb_id: recipient).first
        end
      end

      if user
        has_teacher = !(user.teacher.nil?)
        has_school  = !(user.school.nil?)
        has_both    = has_teacher and has_school
        has_none    = !(has_teacher or has_school)

        replace = 'school'  if has_school
        replace = 'teacher' if has_teacher
        replace = 'both'    if has_both
        replace = 'none'    if has_none

        new_stub = trans_stub.gsub(/_+poc_+/i, replace)
        return new_stub
      else
        return trans_stub
      end
  end

  def name_codes(str, recipient, day=nil, locale=nil)
    # look into passing a user
      if recipient.is_a? User
        user = recipient
        user.reload
      else
        user = User.where(phone: recipient).first
        if user.nil? # try facebook
          user = User.where(fb_id: recipient).first
        end
      end

      if user
        parent  = user.first_name.nil? ? "" : user.first_name
        puts "name_codes parent = #{parent} for #{recipient}"
        
        if locale
          I18n.locale = locale
        else
          I18n.locale = user.locale
        end

        child   = user.child_name.nil? ? I18n.t('defaults.child') : user.child_name.split[0]
        
        if !user.teacher.nil?
          sig = user.teacher.signature
          teacher = sig.nil?           ? "StoryTime" : sig
        else
          teacher = "StoryTime"
        end
        puts "name_codes teacher = #{teacher} for #{recipient}"

        if user.school
          sig = user.school.signature
          school = sig.nil?   ? "StoryTime" : sig
        else
          school = "StoryTime"
        end
        puts "name_codes school = #{school} for #{recipient}"

        if !day.nil?
          weekday = I18n.t('week')[day]
          str = str.gsub(/_+DAY_+/i, weekday)
        end
        
        code = user.code
        if code.nil?
          code = "READ"
        end

        str = str.gsub(/_+CODE_+/i, code)
        str = str.gsub(/_+TEACHER_+/i, teacher)
        str = str.gsub(/_+PARENT_+/i, parent)
        str = str.gsub(/_+SCHOOL_+/i, school)
        str = str.gsub(/_+CHILD_+/i, child)
        return str
      else # just return what we started with. It's 
        str = str.gsub(/_+CODE_+/i, 'go')
        str = str.gsub(/_+TEACHER_+/i, 'StoryTime')
        str = str.gsub(/_+PARENT_+/i, '')
        str = str.gsub(/_+SCHOOL_+/i, 'StoryTime')
        str = str.gsub(/_+CHILD_+/i, 'your child')
        return str
      end
  end
end