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
      
      # We will conver to this
      nodes = []
      edges = []
      
      # Example json tweet:
      #{"archivesource":"twitter-search",
      #"text":"RT @netbeans: Building a simple AtomPub client w #NetBeans, #Maven, #Java &amp; #Apache Abdera: http:\/\/t.co\/NQcUi32k",
      #"to_user_id":"",
      #"from_user":"banumelody",
      #"id":"129498621086408704",
      #"from_user_id":"277264632",
      #"iso_language_code":"en",
      #"source":"&lt;a href=&quot;http:\/\/www.hootsuite.com&quot; rel=&quot;nofollow&quot;&gt;HootSuite&lt;\/a&gt;",
      #"profile_image_url":"http:\/\/a1.twimg.com\/profile_images\/1605902800\/Hytgs0pn_normal",
      #"geo_type":"",
      #"geo_coordinates_0":"0",
      #"geo_coordinates_1":"0",
      #"created_at":"Thu, 27 Oct 2011 10:04:11 +0000",
      #"time":"1319709851"}
      
      # Add all nodes. Don't yet care if they are unique.
      for tweet in tweets
        nodes.push({ :id => tweet["from_user_id"], :label => tweet["from_user"] })
      end
      
      ##########################################################################
      # output xml
      # 
      # fuck xmlsimple. Hashes don't order too well.
      ##########################################################################
      
      now = Time.now
      xml_last_modified_date = "#{now.year}-#{now.month}-#{now.day}"
      xml_creator = screen_name
      xml_description = "gephi_keeper GEXF output for keyword '#{keyword}' at (#{xml_last_modified_date}). Tags: '#{tags}'. Number of tweets: #{count}. Description: #{description}"
      
#      nodes = [ 
#        { :id => 0, :label => "Hello" }, 
#        { :id => 1, :label => "World" } ]
#      edges = [ 
#        { :id => 0, :source => 0, :target => 1 } 
#        ]
      
      xml = Builder::XmlMarkup.new( :target => $stdout, :indent => 2 )
      
      xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
      
      xml.gexf :xmlns => "http://www.gexf.net/1.2draft", :version => "1.2" do
        xml.graph do
          xml.meta :lastmodifieddate => xml_last_modified_date do
            xml.creator xml_creator
            xml.description xml_description
          end
          xml.nodes do
            nodes.each do |node|
              xml.node node
            end
          end
          xml.edges do
            edges.each do |edge|
              xml.edge edge
            end
          end
        end
      end
      
      ##########################################################################
      # fin
      ##########################################################################
      
      true
    end
  end
end