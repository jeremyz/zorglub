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
                File.join @r, args.map { |x| x.to_s }
            end
            #
            def call env
                meth, *args =  env['PATH_INFO'][1..-1].split '/'
                meth||= 'index'
                node = self.new env, {:engine=>engine,:layout=>layout,:view=>r(meth),:method=>meth,:args=>args}
                return error_404 node if not node.respond_to? meth
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
        attr_reader :action, :request, :response
        #
        def initialize env, action
            @env = env
            @action = action
            @request = Rack::Request.new env
            @response = Rack::Response.new
        end
        #
        def realize
            catch(:stop_realize) {
                @content = self.send @action[:method], *@action[:args]
                e, v, l = Config.engine_proc(@action[:engine]), view, layout
                # TODO compile and cache
                @content = e.call v, self if e and File.exists? v
                @content = e.call l, self if e and File.exists? l
                response.write @content
                response.finish
                response
            }
        end
        #
        def redirect target, options={}, &block
            status = options[:status] || 302
            body   = options[:body] || redirect_body(target)
            header = response.header.merge('Location' => target.to_s)
            throw :stop_realize, Rack::Response.new(body, status, header, &block)
        end
        #
        def redirect_body target
            "You are being redirected, please follow this link to: <a href='#{target}'>#{target}</a>!"
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
        def session
            @session ||= Session.new @request
        end
        #
        def r *args
            File.join map, (args.empty? ? @action[:method] : args.map { |x| x.to_s } )
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
