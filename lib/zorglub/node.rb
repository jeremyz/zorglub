# -*- coding: UTF-8 -*-
#
module Zorglub
    #
    class Node
        #
        @hooks = {
            :before_all => [],
            :after_all => [],
        }
        #
        @inherited_vars = { }
        #
        class << self
            #
            attr_reader :hooks, :inherited_vars
            #
            def inherited sub
                sub.layout layout
                sub.engine engine
                sub.instance_variable_set :@inherited_vars, {}
                @inherited_vars.each do |s,v| sub.inherited_var s, *v end
            end
            #
            def engine engine=nil
                @engine = engine unless engine.nil? or engine.empty?
                @engine ||= Config.engine
            end
            #
            def layout layout=nil
                @layout = layout unless layout.nil? or layout.empty?
                @layout ||= Config.layout
            end
            #
            def inherited_var sym, *args
                var = @inherited_vars[sym] ||=[]
                unless args.empty?
                    var.concat args
                    var.uniq!
                end
                var
            end
            #
            attr_accessor :app
            def map app, location
                @app = app
                @app.map location, self
            end
            #
            def r *args
                @r ||= @app.to self
                (args.empty? ? @r : File.join( @r, args.map { |x| x.to_s } ) )
            end
            #
            def call env
                meth, *args =  env['PATH_INFO'].sub(/^\//,'').split '/'
                meth||= 'index'
                node = self.new env, {:engine=>engine,:layout=>layout,:view=>r(meth),:method=>meth,:args=>args}
                return error_404 node if not node.respond_to? meth
                node.realize!
            end
            #
            def partial meth, *args
                node = self.new nil, {:engine=>engine,:layout=>nil,:view=>r(meth),:method=>meth.to_s,:args=>args}
                return error_404 node if not node.respond_to? meth
                node.feed!
                node.content
            end
            #
            def call_before_hooks obj
                Node.hooks[:before_all].each do |blk| blk.call obj end
            end
            #
            def before_all &blk
                Node.hooks[:before_all]<< blk
                Node.hooks[:before_all].uniq!
            end
            #
            def call_after_hooks obj
                Node.hooks[:after_all].each do |blk| blk.call obj end
            end
            #
            def after_all &blk
                Node.hooks[:after_all]<< blk
                Node.hooks[:after_all].uniq!
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
        attr_reader :options, :request, :response, :content, :mime
        #
        def initialize env, options
            @env = env
            @options = options
            @request = Rack::Request.new env
            @response = Rack::Response.new
        end
        #
        def realize!
            catch(:stop_realize) {
                feed!
                response.write @content
                response.header['Content-Type'] = @mime||'text/html'
                response.finish
                response
            }
        end
        #
        def feed!
            state :pre_cb
            Node.call_before_hooks self
            state :meth
            @content = self.send @options[:method], *@options[:args]
            v, l, e = view, layout, Config.engine_proc(@options[:engine])
            state (@options[:layout].nil? ? :partial : :view)
            @content, mime = e.call v, self if e and File.exists? v
            @mime = mime unless mime.nil?
            state :layout
            @content, mime = e.call l, self if e and File.exists? l
            @mime = mime unless mime.nil?
            state :post_cb
            Node.call_after_hooks self
            state :finished
            return @content, @mime
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
        def state state=nil
            @options[:state] = state unless state.nil?
            @options[:state]
        end
        #
        def engine engine=nil
            @options[:engine] = engine unless engine.nil? or engine.empty?
            @options[:engine]
        end
        #
        def layout layout=nil
            @options[:layout] = layout unless layout.nil? or layout.empty?
            return '' if @options[:layout].nil?
            File.join(Config.layout_base_path, @options[:layout])+ Config.engine_ext(@options[:engine])
        end
        #
        def no_layout
            @options[:layout] = nil
        end
        #
        def view view=nil
            @options[:view] = view unless view.nil? or view.empty?
            return '' if @options[:view].nil?
            File.join(Config.view_base_path, @options[:view])+Config.engine_ext(@options[:engine])
        end
        #
        def inherited_var sym, *args
            d = self.class.inherited_vars[sym].clone || []
            unless args.empty?
                d.concat args
                d.uniq!
            end
            d
        end
        #
        def app
            self.class.app
        end
        #
        def args
            @options[:args]
        end
        #
        def map
            self.class.r
        end
        #
        def r *args
            File.join map, (args.empty? ? @options[:method] : args.map { |x| x.to_s } )
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
