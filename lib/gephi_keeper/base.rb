require 'rubygems'
# json
require 'json'
# options_checker
require 'options_checker'
# xml-simple (note without '-')
require 'xmlsimple'

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
      
      now = Time.now.to_date
      xml_last_modified_date = "#{now.year}-#{now.month}-#{now.day}"
      xml_creator = screen_name
      xml_description = description
      
      nodes = [ { :id => 0, :label => "Hello" }, { :id => 1, :label => "Word" } ]
      edges = [ { :id => 0, :source => 0, :target => 1 } ]
      
      xml_options = { "XmlDeclaration" => true, 'KeepRoot' => true }
      xml_output = XmlSimple.xml_out({ :gexf => { :xmlns => "http://www.gexf.net/1.2draft", :version => "1.2", 
            :meta => { :lastmodifieddate => xml_last_modified_date, :creator => [ xml_creator ], :description => [ xml_description ] },
            :graph => { :nodes => { :node => nodes }, :edges => { :edge => edges } } } }, xml_options)
      
      puts xml_output
      
      true
    end
  end
end