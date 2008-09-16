require 'rubygems'
require 'spec'
require 'spec/rake/spectask'
require 'pathname'

ROOT = Pathname(__FILE__).dirname.expand_path
require ROOT + 'lib/dm-is-taggable/is/version'

AUTHOR = "Aaron Qian, Maxime Guilbot"
EMAIL  = "team [a] ekohe [d] com"
GEM_NAME = "dm-is-taggable"
GEM_VERSION = DataMapper::Is::Taggable::VERSION
GEM_DEPENDENCY_VERSION = DataMapper::Is::Taggable::DEPENDENCY_VERSION
GEM_DEPENDENCIES = [["dm-core", GEM_DEPENDENCY_VERSION], ["dm-aggregates", GEM_DEPENDENCY_VERSION]]
GEM_CLEAN = ["log", "pkg"]
GEM_EXTRAS = { :has_rdoc => false, :extra_rdoc_files => %w[ README.textile LICENSE TODO ] }

PROJECT_NAME = "dm-is-taggable"
PROJECT_URL  = "http://github.com/aq1018/dm-is-taggable"
PROJECT_DESCRIPTION = PROJECT_SUMMARY = "Tagging implementation for DataMapper"

require 'tasks/hoe'

task :default => [ :spec ]

WIN32 = (RUBY_PLATFORM =~ /win32|mingw|cygwin/) rescue nil
SUDO  = WIN32 ? '' : ('sudo' unless ENV['SUDOLESS'])

desc "Install #{GEM_NAME} #{GEM_VERSION}"
task :install => [ :package ] do
  sh "#{SUDO} gem install --local pkg/#{GEM_NAME}-#{GEM_VERSION} --no-update-sources", :verbose => false
end

desc "Uninstall #{GEM_NAME} #{GEM_VERSION} (default ruby)"
task :uninstall => [ :clobber ] do
  sh "#{SUDO} gem uninstall #{GEM_NAME} -v#{GEM_VERSION} -I -x", :verbose => false
end

desc 'Run specifications'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts << '--options' << 'spec/spec.opts' if File.exists?('spec/spec.opts')
  t.spec_files = Pathname.glob(Pathname.new(__FILE__).dirname + 'spec/**/*_spec.rb')

  begin
    t.rcov = ENV.has_key?('NO_RCOV') ? ENV['NO_RCOV'] != 'true' : true
    t.rcov_opts << '--exclude' << 'spec'
    t.rcov_opts << '--text-summary'
    t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
  rescue Exception
    # rcov not installed
  end
end
