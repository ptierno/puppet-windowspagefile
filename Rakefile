require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'

desc "Validate ruby files"
task :validate do
  Dir['spec/**/*.rb','lib/**/*.rb'].each do |ruby_file|
    sh "ruby -c #{ruby_file}" unless ruby_file =~ /spec\/fixtures/
  end
end
