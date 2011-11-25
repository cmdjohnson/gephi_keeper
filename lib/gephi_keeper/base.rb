require 'rubygems'
# json
require 'json'
# options_checker
require 'options_checker'
# builder
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
      
      start_time = Time.parse(tweets.last["created_at"])
      end_time = Time.parse(tweets.first["created_at"])
      converted_start_time = convert_time_to_gexf_integer(start_time)
      converted_end_time = convert_time_to_gexf_integer(end_time)
      
      # We will convert to this
      nodes = {}
      edges = {}
      # Generic attributes for each node in this population.
      attributes = []
      # Define attributes.
      attributes.push({ :title => "num_tweets", :type => "integer" })
      attributes.push({ :title => "num_mentions", :type => "integer" })
      
      # But use this indirect representation first.
      # +_+ #
      occurrences ||= {}
      # Count the number of mentions with this hash.
      mentions ||= {}
      
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
        # Don't distinguish oracle and Oracle.
        username = tweet["from_user"].downcase
        # Make the hash if it wasn't already there.
        occurrences[username] ||= {}
        o = occurrences[username]
        # Count the number of times this user exists in this export
        o ||= {}
        # Tweet array.
        o[:tweets] ||= []
        # Now push this tweet occurence to that user.
        o[:tweets].push(tweet)
        
        # Check for the first tweet from this user.
        # We are only interested in the date of the first tweet and none other.
        # +_+ #
        parsed_time = Time.parse(tweet["created_at"])
        # Was it before the existing tweet, if any?
        if o[:first_tweeted_at].nil?
          my_parsed_time = parsed_time
        else
          my_parsed_time = parsed_time if parsed_time < o[:first_tweeted_at]
        end
        # +_+ #
        o[:first_tweeted_at] = my_parsed_time
        
        # Extract references.
        o[:references] ||= {}
        # All references in this tweet.
        # +_+ #
        refs = tweet["text"].scan(/@(\w+)/) # => [["netbeans"], ["zozo"], ["bozozo"]]
        # +_+ #
        for ref in refs
          # Oracle is the same as oracle
          my_ref = ref.first.downcase
          # Also add this user to the nodes list.
          occurrences[my_ref] ||= {}
          occurrences[my_ref][:first_tweeted_at] ||= my_parsed_time          
          # +_+ #
          o[:references][my_ref] ||= { :count => 0 }
          ref_p = o[:references][my_ref]
          # Increase count.
          ref_p[:count] += 1
          # Also increase the count of the global mentions in this population.
          mentions[my_ref] ||= 0
          # +_+ #
          mentions[my_ref] += 1
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
        # +_+ #
        node_options = {}
        # +_+ #
        num_tweets = 0
        # +_+ #
        begin
          num_tweets = occurrences[key][:tweets].count
        rescue
        end
        # +_+ #
        num_mentions = mentions[key] || 0
        # +_+ #
        node_options = { :attributes => { 
            :id => key, 
            :label => key, 
            :start => convert_time_to_gexf_integer(occurrences[key][:first_tweeted_at]),
            :end => converted_end_time
          },
          :size => num_mentions,
          :intensity => num_tweets,
          :attvalues => [
            # 0 = tweets, 1 = mentions
            { :value => num_tweets, :for => "0" },
            { :value => num_mentions, :for => "1" } 
          ]
        }
        # Now using Hash instead of Array
        nodes[key] = node_options
        # +_+ #
        if occurrences[key][:references]
          occurrences[key][:references].keys.each do |reference|
            # +_+ #
            edge_key = "#{key}-#{reference}"
            # +_+ #
            reference_count = occurrences[key][:references][reference][:count]
            # +_+ #
            edges[edge_key] = { :id => edge_key, :source => key, 
              :target => reference, 
              :weight => reference_count,
              :label => reference_count
            }
          end
        end
      end
      
      ##########################################################################
      # output xml
      # 
      # fuck xmlsimple. Hashes don't order too well.
      ##########################################################################
      
      now = Time.now
      xml_last_modified_date = convert_time_to_gexf_date(now)
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
      
      xml.gexf :xmlns => "http://www.gexf.net/1.1", :version => "1.1", "xmlns:viz" => "http://www.gexf.net/1.1draft/viz" do
        xml.graph :mode => "dynamic", :start => converted_start_time, :end => converted_end_time, :timeformat => "integer" do
          xml.meta :lastmodifieddate => xml_last_modified_date do
            xml.creator xml_creator
            xml.description xml_description
          end
          xml.attributes :class => :node do
            for attribute in attributes
              xml_attribute_options = { :id => attributes.index(attribute) }
              xml.attribute xml_attribute_options.merge(attribute)
            end
          end
          xml.nodes do
            nodes.each do |key, node|
              # ATTRIBUTES ATTRIBUTES ATTRIBUTES ATTRIBUTES ATTRIBUTES ATTRIBUTES 
              xml.node node[:attributes] do
                # VIZ VIZ VIZ VIZ VIZ VIZ VIZ VIZ VIZ VIZ VIZ VIZ VIZ VIZ VIZ VIZ 
                xml.viz :size, :value => node[:size]
                xml.viz :color, intensity_to_gexf_color(node[:intensity])
                # ATTVALUES ATTVALUES ATTVALUES ATTVALUES ATTVALUES ATTVALUES ATTVALUES 
                xml.attvalues do
                  for attvalue in node[:attvalues]
                    xml.attvalue attvalue
                  end
                end
                # PARENTS PARENTS PARENTS PARENTS PARENTS PARENTS PARENTS PARENTS 
                if occurrences[key][:references]
                  unless occurrences[key][:references].keys.count.eql?(0)
                    xml.parents do
                      occurrences[key][:references].keys.each do |reference|
                        xml.parent :for => reference
                      end
                    end
                  end
                end
              end
            end
          end
          xml.edges do
            edges.each do |key, edge|
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
    
    def self.convert_time_to_gexf_date(time)
      raise "Need Time object" unless time.is_a? Time
      
      "#{time.year}-#{time.month}-#{time.day}"
    end
    
    def self.convert_time_to_gexf_integer(time)
      raise "Need Time object" unless time.is_a? Time
      
      time.to_i
    end
    
    def self.intensity_to_gexf_color(intensity)
      r = 0
      g = 0
      b = 0
      a = 0.7
      
      r_increment = 10 * intensity
      r_increment = 255 if r_increment > 255
      r += r_increment
        
      a_increment = 0.01 * intensity
      
      a_increment = 0.3 if a_increment > 0.3
      a += a_increment
      
      { :r => r, :g => g, :b => b, :a => a }
    end
  end
end