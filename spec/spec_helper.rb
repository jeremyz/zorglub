#! /usr/bin/env ruby

begin
    require 'coveralls'
    Coveralls.wear!
rescue LoadError
end
begin
    require 'simplecov'
    SimpleCov.start do
        add_filter 'spec'
    end
rescue LoadError
end

require 'yaml'

require 'zorglub'
require 'zorglub/engines/file'
require 'zorglub/engines/haml'
require 'zorglub/engines/sass'

HASH_PROC = Proc.new { |path,obj| {:path=>path,:layout=>obj.layout,:view=>obj.view,:args=>obj.args,:map=>obj.map}.to_yaml }
STATIC_PROC = Proc.new { |path,obj| ["VAL #{obj.value}",'text/static'] }
RENDER_PROC = Proc.new { |path,obj|
    case obj.state
    when :layout
        "layout_start #{obj.content} layout_end"
    when :view
        ["view_content", 'text/view']
    when :partial
        ['partial_content','text/partial']
    else
        raise Exception.new
    end
}
APP_ROOT = File.join Dir.pwd, 'spec', 'data'

class Zorglub::Node
    def self.my_call uri
        call( {'PATH_INFO'=>uri} )
    end
    def self.my_call_i uri
        call( {'PATH_INFO'=>uri} ).body[0].to_i
    end
end

class Temp < Zorglub::Node
end

class Node0 < Zorglub::Node
    # default
    def index
        html
    end
    def hello
        no_layout!
        'world'
    end
    def with_2args a1, a2
    end
    def do_render
        engine! 'real'
    end
    def do_content_type
        engine! 'real'
        response.header['Content-Type'] = 'text/mine'
    end
    def do_partial a1, a2
        engine! 'real'
    end
    def other_view
        engine! 'real'
        view! r('do_partial')
    end
    def do_redirect
        redirect r(:do_partial,1,2,3)
    end
    def xml_file
        no_layout!
        engine! :file
        ext! 'xml'
        mime! 'application/xml'
    end
    def plain_file
        no_layout!
        engine! :file
        ext! 'txt'
        mime! 'text/plain'
    end
    def no_view_no_layout
        no_view!
        no_layout!
        'hello world'
    end
    def engines name
        no_layout!
        case name
        when 'haml'
            engine! :haml
        when 'sass'
            engine! :sass
        end
    end
end

class Node1 < Zorglub::Node
    layout! 'layout-1'
    engine! 'engine-1'
    def index
        layout! 'main'
        engine! 'engine-2'
    end
end

class Node2 < Node1
    # inherited from Node1
end

class Node3 < Zorglub::Node
    @before=0
    @after=0
    class << self
        attr_accessor :before, :after
        def post obj
            @after +=1
        end
    end
    before_all do |node|
        Node3.before +=1
    end
    after_all Node3.method(:post)
    layout! 'layout-2'
    engine! 'engine-2'
    def index
        Node3.before-Node3.after
    end
    def do_partial a1, a2
        view! Node0.r('do_partial')
        engine! 'real'
    end
end

class Node8 < Node3
end

class Node4 < Zorglub::Node
    no_layout!
    cli_val :js,'js0'
    cli_val :js,'js1'
    def index
        cli_val(:js).to_yaml
    end
    def more
        cli_val :js,'js2'
        cli_val(:js).to_yaml
    end
end

class Node5 < Node4
    cli_val :js, 'js3'
    cli_val :css, 'css0', 'css1'
    # no_layout! inherited from Node4
    def index
        js = cli_val(:js,'jsx')
        cli_val(:css, 'css0', 'css1','css2')
        css = cli_val :css
        js.concat(css).to_yaml
    end
end

class Node6 < Zorglub::Node
    @static_cpt=0
    class << self
        attr_accessor :static_cpt
    end
    attr_reader :value
    static! true, 5
    def no_static
        static! false
        engine! 'static'
        view! Node0.r('do_render')
        Node6.static_cpt+=1
        @value = Node6.static_cpt
    end
    def do_static
        engine! 'static'
        view! Node0.r('do_render')
        Node6.static_cpt+=1
        @value = Node6.static_cpt
    end
end

class Node7 < Zorglub::Node
    layout_base_path! File.join APP_ROOT, 'alt','layout'
    view_base_path! File.join APP_ROOT, 'alt'
    def view_path
        view! 'do_render'
    end
end

APP = Zorglub::App.new do
    register_engine! :file, nil, Zorglub::Engines::File.method(:proc)
    register_engine! :haml, 'haml', Zorglub::Engines::Haml.method(:proc)
    register_engine! :sass, 'scss', Zorglub::Engines::Sass.method(:proc)
    register_engine! 'default', nil, HASH_PROC
    register_engine! 'engine-1', 'spec', HASH_PROC
    register_engine! 'engine-2', 'spec', HASH_PROC
    register_engine! 'real', nil, RENDER_PROC
    register_engine! 'static', nil, STATIC_PROC
    opt! :root, APP_ROOT
    opt! :engine, 'default'
    map '/node0', Node0
    map '/node1', Node1
    map '/node3', Node3
    map '/node4', Node4
    map '/node5', Node5
    map '/node6', Node6
    map '/node7', Node7
    map '/node8', Node8
end

class Node2
    map APP, '/node2'
end
