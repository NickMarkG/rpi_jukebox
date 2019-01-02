#require 'csv'
require 'sqlite3'
#require "net/http"
#require "uri"

=begin
This class manages the sqlite3 database as well as logging
=end

TABLES = ["artists", "albums", "songs"]
LOG_LEVELS = {"INFO" => 0, "WARN" => 1, "ERROR" => 2, "FATAL" => 3, "UNKNOWN"=> 4}

URL = ""


class Database
  
  # Creates database tables if not present
  def initialize(database)
    @database = database
    @log_level = 0 

    @mapped_artists = Hash.new
    (self.select("artists")).each {|a| @mapped_artists.store(a[1].gsub(/[!-@\[-`{-~]/, "").downcase.rstrip, a[1])}

    @mapped_albums = Hash.new
    (self.select("albums")).each {|a| @mapped_albums.store(a[1].gsub(/[!-@\[-`{-~]/, "").downcase.rstrip, a[1])}

    SQLite3::Database.open(@database) do |db|
      db.execute( "CREATE TABLE IF NOT EXISTS artists (Id INTEGER, name TEXT)" )
      db.execute( "CREATE TABLE IF NOT EXISTS albums (Id INTEGER, album_name TEXT, artist_name TEXT)" )
      db.execute( "CREATE TABLE IF NOT EXISTS songs (Id INTEGER, artist_name TEXT, album_name TEXT, song_name TEXT)" )
      db.execute( "CREATE TABLE IF NOT EXISTS logs (severity TEXT, message TEXT, date TEXT)" )
    end
  end

  # Selects songs from database where CONDITION applies and returns a shuffled list
  def shuffle(specification=nil)
    list = []

    if (!(specification==nil))
      selected = self.guess_me(specification)

      selected.each do |song|
        list << song
      end

      shuffled_list = list.shuffle

      return shuffled_list
    else

      selected = self.select("songs")

      selected.each do |song|
        list << song
      end

      shuffled_list = list.shuffle

      return shuffled_list
    end
  end

  # Sets the log level according to severity
  def log_level=(severity)
    @log_level = LOG_LEVELS.values_at(severity.upcase)
  end
  
  # Logs messages according to severity and time into the database
  def log(severity, message)
    severity = LOG_LEVELS.values_at(severity.upcase)

    if severity >= @log_level
      SQLite3::Database.open(@database) do |db|
        db.execute("INSERT INTO logs VALUES( ?, ?, ?)", severity, message, Time.now.to_s)
      end
    end
  end

  # Updates database with information retrieved from sync method
  def update
    TABLES.each do |table|
      updates = self.sync(table)
      SQLite3::Database.open(@database) do |db|
        metadata = db.prepare( "SELECT * FROM #{table}" )
        column_number = metadata.column_count
        question_marks = "?, "*(column_number-1) + "?"

        updates.each do |update|
          p update
          db.execute("insert into #{table} values ( #{question_marks} )", update.split(',')) # TODO pick up here
        end
      end
    end
  end

  def guess_me(unknown_info)

    if (@mapped_artists.has_key?(unknown_info))
     artist_test = self.select("songs", "artist_name", @mapped_artists.fetch(unknown_info))
      if (!(artist_test.empty?))
        return artist_test
      end
    end
=begin
    genre_test = self.select("songs", "genre", unknown_info)
    if (!(genre_test.empty?))
      return genre_test
    end
=end
    if (@mapped_albums.has_key?(unknown_info))
      album_test = self.select("songs", "album_name", @mapped_albums.fetch(unknown_info))
      if (!(album_test.empty?))
        return album_test
      end
    end
    
    return close_enough(unknown_info)

    return "Invalid Request"
  end

  def close_enough(unknown_info)
    @mapped_artists.each do |key, value|
      index = 0
      similarity_count = 0
      while index < unknown_info.length
	if (unknown_info[index] == key[index])
	  similarity_count += 1
	end
        index += 1
      end
      if ((similarity_count.to_f / key.length) > 0.5)
        return self.select("songs", "artist_name", value)
      end 
    end

    @mapped_albums.each do |key, value|
      index = 0
      similarity_count = 0
      while index < unknown_info.length
	if (unknown_info[index] == key[index])
	  similarity_count += 1
	end
        index += 1
      end
      if ((similarity_count.to_f / key.length) > 0.2)
        return self.select("songs", "album_name", value)
      end
    end
  end

  # Opens, selects and closes database
  def select(table_name, condition_1=nil, condition_2=nil)      
    if condition_1 == nil && condition_2 == nil

      SQLite3::Database.open(@database) do |db|
        selected = db.execute( "SELECT * FROM #{table_name}" )
        return selected
      end

    else

      SQLite3::Database.open(@database) do |db|
        selected = db.execute( "SELECT * FROM #{table_name} WHERE #{condition_1} = '#{condition_2}'" )
        return selected
      end
    end
  end
end
