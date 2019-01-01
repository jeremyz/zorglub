#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

$:.push File.expand_path("../lib", __FILE__)

begin
    require 'zorglub'
rescue LoadError
end

Gem::Specification.new do |s|
    s.name = "zorglub"
    s.version = Zorglub::VERSION
    s.authors = ["Jérémy Zurcher"]
    s.email = ["jeremy@asynk.ch"]
    s.homepage = "http://github.com/jeremyz/zorglub"
    s.summary = %q{a nano web application framework based on rack }
    s.description = %q{This is a very stripped down version of innate.}

    s.files = `git ls-files`.split("\n")
    s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
    s.require_paths = ["lib"]
end

# EOF
