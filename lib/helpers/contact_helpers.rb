module ContactHelpers

	def email_admins(subject, body)
		Pony.mail(:to => 'phil.esterman@yale.edu',
	            :cc => 'david.mcpeek@yale.edu',
	            :from => 'david.mcpeek@yale.edu',
	            :subject => subject,
	            :body => body)
	end

	
end
