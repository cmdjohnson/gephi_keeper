require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/gephi_keeper'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'gephi_keeper' do
  self.developer 'Commander Johnson', 'commanderjohnson@gmail.com'
  self.post_install_message = 'PostInstall.txt'
  self.rubyforge_name       = self.name
  self.extra_deps         = [ "json", "options_checker", "xml-simple" ]

end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]
