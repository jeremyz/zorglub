# -*- coding: UTF-8 -*-
#
require './lib/zorglub.rb'
load './tasks/setup.rb'
#
# Project general information
PROJ.name = 'zorglub'
PROJ.authors = 'Jérémy Zurcher'
PROJ.email = 'jeremy@asynk.ch'
PROJ.url = 'http://cgit.asynk.ch/cgi-bin/cgit/zorglub'
PROJ.version = Zorglub::VERSION
PROJ.rubyforge.name = 'FIXME'
PROJ.readme_file = 'README.rdoc'
#
# Annoucement
PROJ.ann.paragraphs << 'FEATURES' << 'SYNOPSIS' << 'REQUIREMENTS' << 'DOWNLOAD/INSTALL' << 'CREDITS' << 'LICENSE'
PROJ.ann.email[:from] = 'jeremy@asynk.ch'
PROJ.ann.email[:to] = ['FIXME']
PROJ.ann.email[:server] = 'FIXME'
PROJ.ann.email[:tls] = false
# Gem specifications
PROJ.gem.need_tar = false
PROJ.gem.files = %w(Changelog MIT-LICENSE README.rdoc Rakefile) + Dir.glob("{ext,lib,spec,tasks}/**/*[^~]").reject { |fn| test ?d, fn }
PROJ.gem.platform = Gem::Platform::RUBY
PROJ.gem.required_ruby_version = ">= 1.9.2"
#
# Override Mr. Bones autogenerated extensions and force ours in
#PROJ.gem.extras['extensions'] = %w(ext/extconf.rb)
#PROJ.gem.extras['required_ruby_version'] = ">= 1.9.2"
#
# RDoc
PROJ.rdoc.exclude << '^ext\/'
PROJ.rdoc.opts << '-x' << 'ext'
#
# Ruby
PROJ.ruby_opts = []
PROJ.ruby_opts << '-I' << 'lib'
#
# RSpec
PROJ.spec.files.exclude /rbx/
PROJ.spec.opts << '--color'
#
# Rcov
PROJ.rcov.opts << '-I lib'
#
# Dependencies
depend_on 'rack'
depend_on 'rake', '>=0.8.0'
#
task :default  => [:spec]
#
desc "Build all packages"
task :package => 'gem:package'
#
desc "Install the gem locally"
task :install => 'gem:install'
#
# EOF
