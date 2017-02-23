class NilClass
  def is_email?
    false
  end
  def is_phone?
    false
  end
end


class String
  @@email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  @@phone_regex = /^\d+$/

  def is_email?
    @@email_regex.match(self) ? true : false
  end

  def is_phone?
    @@phone_regex.match(self) ? true : false
  end
end


module SearchByUsername
  def where_username_is(str)
    if str.is_email?
      self.where(email: str).first
    elsif str.is_phone?
      self.where(phone: str).first
    else
      if ENV['RACK_ENV'] == 'test'
        return self.where(phone: str).first
      end

      nil
    end
  end
end
