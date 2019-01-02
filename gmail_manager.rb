require 'gmail'

class Gmail_manager
	require 'gmail'
	def initialize(username="thewildpibox@gmail.com", password="Nick2wildpi")
		@gmail = Gmail.connect(username, password)
	end

	def listen
		inbox = @gmail.inbox.find(:unread, :from => "thewildpibox@gmail.com")

		while true
			inbox = @gmail.inbox.find(:unread, :from => "thewildpibox@gmail.com")
			if !inbox.empty?
				inbox[0].read!
				inbox[0].archive!
				return inbox[0].message.subject
			end
		end
	end

end