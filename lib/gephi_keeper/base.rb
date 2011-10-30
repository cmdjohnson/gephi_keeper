require 'rubygems'
# json
require 'json'
# options_checker
require 'options_checker'

module GephiKeeper
  class Base
    def self.process_file(options = {})
      OptionsChecker.check(options, [ :filename ])
    end
  end
end