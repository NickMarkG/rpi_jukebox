#!/usr/bin/env ruby
#Dir.chdir("/home/pi/Desktop/Juke Box")
require_relative 'juke_box'
require_relative 'gmail_manager'

@system = Juke_box.new

@system.random

Thread.new {@system.on}


def patience(type)
	# Loop to constantly listen for user input
	loop do
	if type == 'a'
			gmail = Gmail_manager.new
			i = gmail.listen.chomp.downcase
		elsif type == 't'
			i = gets.chomp.downcase
		end

		method_name = i[/^([\w\-]+)/]						# Takes first word of input
		method_args = i[/(?<=\s).*/]						# Takes every word except first from string

		exit if method_name == 'end'

		if Juke_box.method_defined?(method_name)			# Tests if given method is valid

			if method_args == nil							# Sends valid method with or without params
				@system.send(method_name)
			else
				@system.send(method_name, method_args)
			end

			exit if method_name == 'off'					# Safely shuts off program if 'off' method called
		else
			puts("Invalid command")							# Exception if user input !valid command end
		end
	end
end

Thread.new{ patience("a") }

patience("t")

