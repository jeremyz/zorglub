#! /usr/bin/env ruby
#
begin
    require 'simplecov'
    SimpleCov.start do
        add_filter 'spec'
    end
rescue LoadError
end
#
require 'zorglub'
#
ENGINE_PROC = Proc.new { |path,obj| "path=>#{path} : obj=>#{obj}" }
Zorglub::Config.register_engine 'spec-engine-1', 'spec', ENGINE_PROC
Zorglub::Config.register_engine 'spec-engine-2', 'spec', ENGINE_PROC
#
Zorglub::Config.engine = 'haml'
#
class Temp < Zorglub::Node
end
#
class Node0 < Zorglub::Node
    # default
    def hello
        'world'
    end
end
#
class Node1 < Zorglub::Node
    @count=0
    class << self
        attr_accessor :count
    end
    before_all do |node|
        Node1.count +=1
    end
    layout 'spec-layout-1'
    engine 'spec-engine-1'
end
#
class Node2 < Zorglub::Node
    layout 'spec-layout-2'
    engine 'spec-engine-2'
end
#
class Node3 < Node2
    # inherited from Node2
end
#
APP = Zorglub::App.new do
    map '/spec1', Node1
end
class Node2
    map APP, '/spec2'
end
#
