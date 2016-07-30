module ContactHelpers


  def email_admins(subject, body)
    Pony.mail(:to => 'phil.esterman@yale.edu',
              :cc => 'david.mcpeek@yale.edu',
              :from => 'david.mcpeek@yale.edu',
              :headers => { 'Content-Type' => 'text/html' },
              :subject => subject,
              :body => body)
  end

  
end
