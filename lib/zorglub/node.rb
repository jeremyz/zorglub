# -*- coding: UTF-8 -*-
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
            def r *args
                @r ||= @app.to self
                File.join @r, *args
            end
            #
            def call env
                meth, *args =  env['PATH_INFO'][1..-1].split '/'
                meth||= 'index'
                action = {:engine=>engine,:layout=>layout,:view=>File.join(r,meth),:method=>meth,:args=>args}
                node = self.new Rack::Request.new(env), Rack::Response.new, action
                return error_404 node if not node.respond_to? meth
                # TODO
                #  - session
                node.realize
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
        def realize
            @content = self.send @action[:method], *@action[:args]
            e = Config.engine_proc @action[:engine]
            v = view
            l = layout
            @content = e.call v, self if e and File.exists? v
            @content = e.call l, self if e and File.exists? l
            response.write @content
            response.finish
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
# EOF
