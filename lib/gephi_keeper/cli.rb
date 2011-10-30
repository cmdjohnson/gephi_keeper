require 'optparse'
require 'gephi_keeper/base'

module GephiKeeper
  class CLI
    def self.execute(stdout, arguments=[])

      # Defaults for options
      options = {
        :filename     => nil
      }
      mandatory_options = [ :filename ]

      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          Convert tweets from Twitter, output as JSON from TwapperKeeper (www.twapperkeeper.com) into GEXF format for the Gephi graphviz tool. (www.gephi.org)

          Usage: #{File.basename($0)} [options]

          Options are:
        BANNER
        opts.separator ""
        opts.on("-f", "--filename FILENAME", String,
                "Name of input file.") { |arg| options[:filename] = arg }
        opts.on("-h", "--help",
                "Show this help message.") { stdout.puts opts; exit }
        opts.parse!(arguments)
        # Check for mandatory options
        if mandatory_options && mandatory_options.find { |option| options[option.to_sym].nil? }
          stdout.puts opts; exit
        end
      end

      filename = options[:filename]

      # do stuff
      #stdout.puts "To update this executable, look in lib/gephi_keeper/cli.rb"
      GephiKeeper::Base.process_file( :filename => filename )
    end
  end
end