require 'logger'
require 'open3'

=begin
This class creates a ruby interface with omxplayer
=end

#$LOG = Logger.new("omx_log")

class Omxplayer
	
	def initialize(directory)
		@directory = directory
		@volume = -5
	end

	# Turns omxplayer on, tests if arguments are valid, and pauses
	def on?(song, volume, output="local")
		if output != "local" && output != "hdmi"
			#$LOG.error("Invalid output, switching to default")
			#@db.log("error", "Invalid output, switching to default")
			output = "local"
		end
		@stdin, @stdout, @stderr, @wait_thr = Open3.popen3("omxplayer -o #{output} '#{@directory + song}' --vol '#{@volume}'")

		if @wait_thr.alive?
			@stdin.write("-")
			@stdin.write("-")
			@stdin.write("-")
			@stdin.write("-")

			@stdin.write("p")
			true
		else
			false
		end

	end

	# Plays omxplayer
	def play
		@stdin.write("p")
		#$LOG.info("Bell has been rung successfully")
		#@db.log("info", "Bell has been rung successfully")
	end

	# Make private?
	# Closes std's when omxplayer finishes running
	def timer
		sleep 0.1 while @wait_thr.alive?
		self.off
	end

	# Lowers the volume
	def vd(value)
		value.times {@stdin.write("-");@volume -= 300}
	end

	# Increases the volume
	def vu(value)
		value.times {@stdin.write("+");@volume += 300}
	end

	# Turns off omxplayer safely
	def off
		if @wait_thr.alive?
			@stdin.write("q")
		end
		@stdin.close
 	 	@stdout.close
		@stderr.close
		#$LOG.info("Omxplayer has been turned off")
		#@db.log("info", "Omxplayer has been turned off")
	end

	# Rings bell through GPIO
	def signal
		
	end
	
	#Changes directory to folder which contains song
	def change_dir(artist, album)
		@directory = ("/home/pi/Music/#{artist}/#{album}/")
	end

end
