#! /usr/bin/ruby
#
module Zorglub
    #
    class Node
        #
        class << self
            #
            def engine engine=nil
                @engine = engine unless engine.nil?
                @engine ||= Config.engine
            end
            #
            def layout name=nil
                @layout = name unless name.nil?
                @layout ||= Config.default_layout
            end
            #
            attr_writer :app
            def map app, location
                @app = app
                @app.map location, self
            end
            #
            def r
                @r ||= @app.to self
            end
            #
            def call env
                meth, *args =  env['PATH_INFO'][1..-1].split '/'
                meth||= 'index'
                node = self.new Rack::Request.new(env), Rack::Response.new, {:engine=>engine,:layout=>layout,:view=>File.join(r,meth),:method=>meth,:args=>args}
                return error_404 node if not node.respond_to? meth
                # TODO session
                node.send meth, *args
            end
            #
            def error_404 node
                resp = node.response
                resp.status = 404
                resp['Content-Type'] = 'text/plain'
                resp.write "%s mapped at %p can't respond to : %p" % [ node.class.name, node.r, node.request.env['PATH_INFO'] ]
                resp
            end
            #
        end
        #
        attr_reader :request, :response, :action
        #
        def initialize req, res, act
            @action = act
            @request = req
            @response = res
        end
        #
        def engine engine=nil
            @action[:engine] = engine unless engine.nil?
            @action[:engine]
        end
        #
        def layout name=nil
            @action[:layout] = name unless name.nil?
            File.join(Config.layout_base_path, @action[:layout])+'.'+ Config.engine_ext(@action[:engine])
        end
        #
        def view path=nil
            @action[:view] = path unless path.nil?
            File.join(Config.view_base_path, @action[:view])+'.'+Config.engine_ext(@action[:engine])
        end
        #
        def args
            @action[:args]
        end
        #
        def map
            self.class.r
        end
        #
        def r
            File.join map, @action[:method]
        end
        #
        def html
            [ :map, :r, :args, :engine, :layout, :view ].inject('') { |s,sym| s+="<p>#{sym} => #{self.send sym}</p>"; s }
        end
        #
    end
    #
end
#
