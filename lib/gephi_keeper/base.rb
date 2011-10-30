require 'rubygems'
# json
require 'json'
# options_checker
require 'options_checker'
# xml-simple (note without '-')
require 'builder'

module GephiKeeper
  class Base
    def self.process_file(options = {})
      OptionsChecker.check(options, [ :filename ])
      
      ##########################################################################
      # initialize
      ##########################################################################
      
      # Get file object
      file = File.new(options[:filename])
      # Load the file into memory. Could be costly when files are too big ...
      json = JSON.parse(file.read)
      
      ##########################################################################
      # metadata
      ##########################################################################
      
      # Metadata
      create_time = json["archive_info"]["create_time"]
      tags = json["archive_info"]["tags"]
      id = json["archive_info"]["id"]
      count = json["archive_info"]["count"]
      user_id = json["archive_info"]["user_id"]
      description = json["archive_info"]["description"]
      keyword = json["archive_info"]["keyword"]
      screen_name = json["archive_info"]["screen_name"]
      
      ##########################################################################
      # process tweets
      ##########################################################################
      
      # les tweets
      tweets = json["tweets"]
      
      ##########################################################################
      # output xml
      ##########################################################################
      
      
      
      ##########################################################################
      # fin
      ##########################################################################
      
      true
    end
  end
end