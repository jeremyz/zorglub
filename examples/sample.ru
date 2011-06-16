#! /usr/bin/env ruby
#
$LOAD_PATH << File.join(File.dirname( File.absolute_path(__FILE__)), '..', 'lib')
#
require 'zorglub'
#
require 'haml'
HAML_PROC = Proc.new { |path,obj| Haml::Engine.new( File.open(path,'r').read ).render(obj) }
Zorglub::Config.register_engine 'haml', 'haml', HAML_PROC
Zorglub::Config.register_engine 'temp-engine', 'haml', HAML_PROC
#
Zorglub::Config.engine = 'haml'
Zorglub::Config.root = File.dirname( File.absolute_path(__FILE__) )
#
class Node1 < Zorglub::Node
    #
    def index a1, *a2
        @title='Node2'
        #"<title>Node1:index</title><p>a1 : #{a1.inspect}</p><p>a2 : #{a2.inspect}</p>#{html}"
    end
    #
    def alt *args
        "<title>Node1:alt</title>#{html}"
    end
    #
end
#
APP = Zorglub::App.new do
    map '/url1', Node1
end
#
class Node2 < Zorglub::Node
    #
    map APP, '/url2'
    engine 'my-engine'  # not available
    layout 'my-layout'  # not available
    #
    def index *args
        "<title>Node2:alt</title>#{html}"
    end
    #
    def alt *args
        engine 'temp-engine'
        layout 'temp-layout-name'
        view 'path-to-temp-view'
        "<title>Node2:alt</title>#{html}"
    end
    #
end
#
puts APP.to_hash.inspect
#
map '/' do
    use Rack::ShowExceptions
    run APP
end
#
