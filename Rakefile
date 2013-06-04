require "bundler/gem_tasks"

require 'rake/testtask'
require 'rdoc/task'
require 'rake/clean'
#require 'yard/rake/yardoc_task'
require 'yard'

NAME = 'ruby-state-machine'

CLOBBER.include('html/**/*')
CLOBBER.include('doc/**/*')

# use 'rake clean' and 'rake clobber' to
# easily delete generated files

# the same as before
Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test

# Old RDoc stuff:
# Rake::RDocTask.new do |rd|
#   rd.main = "README.md"
#   rd.rdoc_files.include("README.md", "lib/**/*.rb", "ext/**/*.c")
#   rd.title = "Ruby state_machine Gem documentation"
# end

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']   
  t.options = ['--readme=README.md'] 
end

rubyforge_username = "stevenmiers"
rubyforge_project = "ruby-state-machine"
desc 'Upload rdoc files to rubyforge'
task :upload_docs do
  host = "#{rubyforge_username}@rubyforge.org"
  remote_dir = "/var/www/gforge-projects/ruby-state-mach/"
  local_dir = 'doc'
  sh %{scp -r #{local_dir}/* #{host}:#{remote_dir}}
  #sh %{rsync -aCv #{local_dir} #{host}:#{remote_dir}}
end

