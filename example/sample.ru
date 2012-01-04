#! /usr/bin/env ruby
#
$LOAD_PATH << File.join(File.dirname( File.absolute_path(__FILE__)), '..', 'lib')
#
USE_RACK_SESSION=false
#
require 'zorglub'
if USE_RACK_SESSION
    require 'zorglub/rack_session'
else
    require 'zorglub/session'
end
#
require 'haml'
HAML_PROC = Proc.new { |path,obj| Haml::Engine.new( File.open(path,'r').read ).render(obj) }
Zorglub::Config.register_engine 'haml', 'haml', HAML_PROC
Zorglub::Config.register_engine 'tmp-engine', 'haml', HAML_PROC
#
Zorglub::Config.engine = 'haml'
Zorglub::Config.session_on = true
Zorglub::Config.root = File.dirname( File.absolute_path(__FILE__) )
#
class Zorglub::Node
    @count=0
    class << self
        attr_accessor :count
    end
    before_all do |node|
        Zorglub::Node.count +=1
    end
end
#
class Node1 < Zorglub::Node
    #
    def index a1, *a2
        @title='Index'
        @links = LINKS
        # there's a view so the below will be lost !
        "<b>should never be seeen</b>"
    end
    #
    def meth0 *args
        @title='meth0'
        @links = LINKS
        # method level engine
        engine 'tmp-engine'
        # there's a view so the below will be lost !
        "<b>should never be seeen</b>"
    end
    #
    def meth1 *args
        @title='meth1'
        @links = LINKS
        # method level engine (layout/other.haml)
        layout 'other'
        # specific method view (view/url1/meth0.haml)
        view File.join( 'url1','meth0')
        # there's a view so the below will be lost !
        "<b>should never be seeen</b>"
    end
    #
    def jump *args
        redirect r(:index,1,2,3)
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
    layout 'css'
    # class level engine
    engine 'tmp-engine'
    # class level css
    inherited_var :css, 'class_level.css'
    #
    def index *args
        "<title>Node2:index</title><b>START</b>#{html}<a href=#{Node2.r(:meth0)}>next</a><br/><b>END</b>"
    end
    #
    def meth0 *args
        # instance level css
        inherited_var :css, 'instance_level.css'
        "<title>Node2:meth0</title><b>START</b>#{html}<a href=#{Node2.r(:meth1,1,2)}>next</a><br/><b>END</b>"
    end
    #
    def meth1 *args
        more = Node2.partial :meth0, *args
        "<title>Node2:meth1</title><b>partial</b><br/>#{more}<br/><b>done</b><br/><a href=#{Node0.r}>back</a>"
    end
end
#
class Node3 < Zorglub::Node
    #
    map APP, '/url3'
    layout ''
    #
    def index *args
        @title = "Session tests"
        t = Time.now
        if session[:now].nil?
            session[:now] = t
            @data = "#{t.strftime('%H:%M:%S')} FIRST"
        elsif t-session[:now]>10
            session[:now] = t
            @data = "#{t.strftime('%H:%M:%S')} UPDATE"
        else
            @data = "#{session[:now].strftime('%H:%M:%S')} CURRENT"
        end
    end
    def reset
        session.clear
        redirect :index
    end
    #
end
#
class Node0 < Zorglub::Node
    #
    map APP, '/'
    #
    def index
        html = "<html><body><ul>"
        html << "<li><a href=\"#{Node1.r('index','a',2,'c')}\">Node1</a> engine, layout, view, redirect tests</li>"
        html << "<li><a href=\"#{Node2.r}\">Node2</a> css helper tests</li>"
        html << "<li><a href=\"#{Node3.r}\">Node3</a> session test</li>"
        html << "</ul></body></html>"
        html
    end
    #
end
#
Node1::LINKS= [
            [Node1.r('index','arg1','arg2','arg3'),'index'],
            [Node1.r('meth0'),'meth0'],
            [Node1.r('meth1','one','two'),'meth1 with args'],
            [Node1.r('jump','one','two'),'test redirect'],
            [Node0.r,'back'],
]
#
puts APP.to_hash.inspect
puts "  **** "+( USE_RACK_SESSION ? 'USE Rack Session' : 'USE builtin Session' )
#
map '/' do
    use Rack::Lint
    use Rack::ShowExceptions
    if USE_RACK_SESSION
        use Rack::Session::Cookie,  :key=>Zorglub::Config.session_key, :secret=>Zorglub::Config.session_secret,
            :path=>'/', :http_only=>true, :expire_after=>30
    end
    run APP
end
#
