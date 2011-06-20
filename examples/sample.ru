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
Zorglub::Config.session_on = true
Zorglub::Config.root = File.dirname( File.absolute_path(__FILE__) )
#
class Node1 < Zorglub::Node
    #
    include Zorglub::Helpers::Css
    css 'class_level.css'
    #
    def index a1, *a2
        @title='Index'
        css 'instance_level.css'
    end
    #
    def alt *args
        @title='Alt'
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
    include Zorglub::Helpers::Css
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
        @title = "Alt 2"
        engine 'temp-engine'                    # haml renamed
        layout 'other'                          # use layout/other.haml template
        view File.join( 'url1','alt')           # use view/url1/alt.haml template
        if not session.exists?
            @data = "NO SESSION"
        else
            t = Time.now
            if session[:now].nil?
                session[:now] = t
                @data = "#{t.strftime('%H:%M:%S')} FIRST"
            elsif t-session[:now]>5
                session[:now] = t
                @data = "#{t.strftime('%H:%M:%S')} UPDATE"
            else
                @data = "#{session[:now].strftime('%H:%M:%S')} CURRENT"
            end
        end
    end
    #
end
#
puts APP.to_hash.inspect
#
map '/' do
    use Rack::Lint
    use Rack::ShowExceptions
    use Rack::Session::Cookie,  :key=>Zorglub::Session.session_key,
                                :secret=>'my-secret-secret',
                                :path=>'/',
                                :http_only=>true,
                                :expire_after=>30
    run APP
end
#
