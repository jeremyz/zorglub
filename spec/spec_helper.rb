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
require 'yaml'
#
require 'zorglub'
#
HASH_PROC = Proc.new { |path,obj| {:path=>path,:layout=>obj.layout,:view=>obj.view,:args=>obj.args}.to_yaml }
RENDER_PROC = Proc.new { |path,obj|
    m = obj.action[:mode]
    case m
    when :layout
        "layout_start #{obj.content} layout_end"
    when :view
        "view_content"
    else
        raise Exception.new
    end
}
Zorglub::Config.register_engine 'default', nil, HASH_PROC
Zorglub::Config.register_engine 'engine-1', 'spec', HASH_PROC
Zorglub::Config.register_engine 'engine-2', 'spec', HASH_PROC
Zorglub::Config.register_engine 'real', nil, RENDER_PROC
#
Zorglub::Config[:engine] = 'default'
Zorglub::Config.root = File.join Dir.pwd, 'spec', 'data'
#
class Zorglub::Node
    def self.my_call uri
        call( {'PATH_INFO'=>uri} )
    end
end
#
class Temp < Zorglub::Node
end
#
class Node0 < Zorglub::Node
    # default
    def index
        html
    end
    def hello
        layout 'none'
        'world'
    end
    def with_2args a1, a2
    end
    def do_render
        engine 'real'
    end
    def do_partial a1, a2
        engine 'real'
    end
    def other_view
        engine 'real'
        view r('do_partial')
    end
    def do_redirect
        redirect r(:do_partial,1,2,3)
    end
end
#
class Node1 < Zorglub::Node
    layout 'layout-1'
    engine 'engine-1'
    def index
        layout 'main'
        engine 'engine-2'
    end
end
#
class Node2 < Node1
    # inherited from Node1
end
#
class Node3 < Zorglub::Node
    @before=0
    @after=0
    class << self
        attr_accessor :before, :after
    end
    before_all do |node|
        Node3.before +=1
    end
    after_all do |node|
        Node3.after +=1
    end
    layout 'layout-2'
    engine 'engine-2'
    def index
        (self.class.before-self.class.after).should == 1
    end
end
#
APP = Zorglub::App.new do
    map '/node0', Node0
    map '/node1', Node1
    map '/node3', Node3
end
class Node2
    map APP, '/node2'
end
#
