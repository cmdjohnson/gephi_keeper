require 'rubygems'
# json
require 'json'
# options_checker
require 'options_checker'
# xml-simple (note without '-')
require 'builder'
# time
# for 'parse'
require 'time'

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
      
      # We will convert to this
      nodes = []
      edges = []
      # But use this indirect representation first.
      # +_+ #
      occurrences ||= {}
      
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
      
      # Convert to a workable internal representation.
      for tweet in tweets
        #nodes.push({ :id => tweet["from_user_id"], :label => tweet["from_user"] })
        # Make the hash if it wasn't already there.
        occurrences[tweet["from_user"]] ||= {}
        o = occurrences[tweet["from_user"]]
        # Count the number of times this user exists in this export
        o ||= {}
        # Tweet array.
        o[:tweets] ||= []
        # Now push this tweet occurence to that user.
        o[:tweets].push(tweet)
        
        # Check for the first tweet from this user.
        # We are only interested in the date of the first tweet and none other.
        # +_+ #
        parsed_time = Time.parse tweet["created_at"]
        # Was it before the existing tweet, if any?
        if o[:first_tweeted_at].nil?
          o[:first_tweeted_at] = parsed_time
        else
          o[:first_tweeted_at] = parsed_time if parsed_time < o[:first_tweeted_at]
        end
        
        # Extract references.
        o[:references] ||= {}
        # All references in this tweet.
        # +_+ #
        refs = tweet["text"].scan(/@(\w+)/) # => [["netbeans"], ["zozo"], ["bozozo"]]
        # +_+ #
        for ref in refs
          # +_+ #
          o[:references][ref] ||= { :count => 0 }
          ref_p = o[:references][ref]
          # Increase count.
          ref_p[:count] += 1
        end
      end
      
      ##########################################################################
      # Data structure:
      # 
      # occurrences
      #   - [username]
      #     - :tweets                 Array of tweets (Hash objects)
      #     - :first_tweeted_at       Time object when the first tweet from this user was registered.
      #     - :references             Hash of usernames (String) mentioned by this user in any tweet
      #       - [username]
      #         - :count              Number of times referred to username in any tweet
      ##########################################################################
      
      # Now convert to nodes & edges
      occurrences.keys.each do |key|
        num_tweets = occurrences[key][:tweets].count
        nodes.push( { :attributes => { :id => key, :label => num_tweets, :start => convert_time_to_gexf_time(occurrences[key][:first_tweeted_at]) },
            :size => num_tweets
          } )
        # +_+ #
        occurrences[key][:references].keys.each do |reference|
          edges.push( { :id => "#{key}-#{reference}", :source => key, :target => reference, :weight => occurrences[key][:references][reference][:count] } )
        end
      end
      
      ##########################################################################
      # output xml
      # 
      # fuck xmlsimple. Hashes don't order too well.
      ##########################################################################
      
      now = Time.now
      xml_last_modified_date = convert_time_to_gexf_time(now)
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
      
      xml.gexf :xmlns => "http://www.gexf.net/1.2draft", :version => "1.2", "xmlns_viz" => "http://www.gexf.net/1.1draft/viz" do
        xml.graph :timeformat => "date" do
          xml.meta :lastmodifieddate => xml_last_modified_date do
            xml.creator xml_creator
            xml.description xml_description
          end
          xml.nodes do
            nodes.each do |node|
              xml.node node[:attributes] do
                xml.viz :size, :value => node[:size]
              end
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
    
    protected
    
    def self.convert_time_to_gexf_time(time)
      raise "Need Time object" unless time.is_a? Time
      
      "#{time.year}-#{time.month}-#{time.day}"
    end
  end
end