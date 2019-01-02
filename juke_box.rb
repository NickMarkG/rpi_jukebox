require_relative 'omxplayer'
require_relative 'database'
require 'logger'

=begin
This class is the brains of the bell system. It controls the
Calendar, schedule, event, omxplayer, --- to ring the bell
at the appropriate time (plus other bells and whistles).
=end

#DAYS = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
MUSIC_DATABASE = "Music.db"
MUSIC_DIRECTORY = "/home/pi/Music/"

class Juke_box
  def initialize 
    @db = Database.new(MUSIC_DATABASE)
    @music = Omxplayer.new(MUSIC_DIRECTORY)
    @playlist = []
    @count = 0
    @volume_count = 0
    @repeat = false
  end

  # Loops through playlist until empty
  def on
    loop do
     while @count < @playlist.size
      self.play_music
      self.wait
     end
     if (@repeat)                    # If @repeat is true, resets playlist and loops through again
       @count = 0
     else
       break
     end
    end
    @count = 0
  end

  # Returns shuffled list of entire database
  def random
    @playlist = @db.shuffle
  end

  # Plays the next song in @playlist
  def play_music
   	song_set = @playlist[@count]
    @count += 1
    @song = Thread.new do
    	@music.change_dir(song_set[1], song_set[2])
      if !@music.on?(song_set[3], @volume_count)      # Runs omxplayer and kills thread if unsuccessful
        self.kill
		  end

		puts("Song #{song_set[3]} Starting")
  	puts("Sleeping for #{song_set[4]}++ seconds\n")
                
    @music.play
		@music.timer
    end
  end

  # Skips to the next song in the playlist
  def skip
    @song.kill
    @music.off
  end

  # Goes to previous song in playlist
  def previous	  
    @music.off
    @song.kill
    @count -= 2
  end

  # Creates new playlist and resets 'on' loop after killing current song
  def shuffle(artist=nil)
    @playlist.clear
    @playlist = @db.shuffle(artist)
    @music.off
    @song.kill
    @count = 0
  end

  def pause
	  @music.play
  end

  # Volume down from user to omxplayer
  def vd(value=1)
    @music.vd(value.to_i)
  end

  # Volume up from user to omxplayer
  def vu(value=1)
    @music.vu(value.to_i)
  end

  # Toggles repeat value
  def repeat(toggle="on")
    @repeat = true if toggle == "on"
    @repeat = false if toggle == "off"    
  end

  # Waits until @song has finished executing
  def wait
   sleep 0.1 while @song.alive?
   #puts "Here!"
  end

  # Safely turns off music
  def off
    @music.off
    @playlist.clear
    @song.kill
  end

  def to_s
  	
  end
end
