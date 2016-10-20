module NameCodes

  def self.included(base)
    base.extend(self)
  end

  def teacher_school_messaging(trans_stub, recipient) # for translation stub? first thing i thought of
      if (/__poc__/).match(trans_stub).nil? # if no match, just return the original stub
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
        # replace = 'both'    if has_both
        replace = 'none'    if has_none

        new_stub = trans_stub.gsub(/__poc__/, replace)
        return new_stub
      else
        return trans_stub
      end
  end

  def name_codes(str, recipient, day=nil)
      puts "USING NAME_CODES IN DSL.RB"
      if recipient.is_a? User
        user = recipient
      else
        user = User.where(phone: recipient).first
        if user.nil? # try facebook
          user = User.where(fb_id: recipient).first
        end
      end

      puts "name codes str = #{str.inspect}"

      if user
        parent  = user.first_name.nil? ? "" : user.first_name
        I18n.locale = user.locale
        child   = user.child_name.nil? ? I18n.t('defaults.child') : user.child_name.split[0]
        
        if !user.teacher.nil?
          sig = user.teacher.signature
          teacher = sig.nil?           ? "StoryTime" : sig
        else
          teacher = "StoryTime"
        end

        if user.school
          sig = user.school.signature
          school = sig.nil?   ? "StoryTime" : sig
        else
          school = "StoryTime"
        end

        if !day.nil?
          weekday = I18n.t('week')[day]
          str = str.gsub(/__DAY__/, weekday)
        end
        
        code = user.code
        if code.nil?
          code = "READ"
        end

        str.gsub!(/__CODE__/, code)
        str.gsub!(/__TEACHER__/, teacher)
        str.gsub!(/__PARENT__/, parent)
        str.gsub!(/__SCHOOL__/, school)
        str.gsub!(/__CHILD__/, child)
        return str
      else # just return what we started with. It's 
        str.gsub!(/__CODE__/, 'go')
        str.gsub!(/__TEACHER__/, 'StoryTime')
        str.gsub!(/__PARENT__/, '')
        str.gsub!(/__SCHOOL__/, 'StoryTime')
        str.gsub!(/__CHILD__/, 'your child')
        return str
      end
  end
end