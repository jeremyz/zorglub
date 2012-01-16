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
            attr_reader :hooks, :inherited_vars, :layout
            #
            def inherited sub
                sub.layout! layout||(self==Zorglub::Node ? Config.layout : nil )
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
            def no_layout!
                @layout = nil
            end
            #
            def layout! layout
                @layout = layout
            end
            #
            def static val=nil
                @static = val if (val==true or val==false)
                @static ||=false
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
                puts "=> #{meth}(#{args.join ','})" if Config.debug
                node = self.new env, {:engine=>engine,:layout=>layout,:view=>r(meth),:method=>meth,:args=>args,:static=>static}
                return error_404 node if not node.respond_to? meth
                node.realize!
            end
            #
            def partial meth, *args
                node = self.new nil, {:engine=>engine,:layout=>nil,:view=>r(meth),:method=>meth.to_s,:args=>args,:static=>static}
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
                puts " !! method not found" if Config.debug
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
            static_path = static
            if static_path.nil?
                compile!
            else
                static! static_path
            end
            state :post_cb
            Node.call_after_hooks self
            state :finished
            return @content, @mime
        end
        #
        def static! path
            if not File.exists? path
                compile!
                Dir.mkdir Config.static_base_path
                Dir.mkdir File.dirname path
                File.open(path, 'w') {|f| f.write("@mime:"+@mime+"\n"); f.write(@content); }
                puts " * cache file created : #{path}" if Config.debug
            else
                puts " * use cache file : #{path}" if Config.debug
                content = File.open(path, 'r') {|f| f.read }
                @content = content.sub /^@mime:(.*)\n/,''
                @mime = $1
            end
        end
        #
        def compile!
            e, @options[:ext] = Config.engine_proc_ext @options[:engine], @options[:ext]
            v, l = view, layout
            if Config.debug
                puts " * "+(File.exists?(l) ? 'use layout' : 'not found layout')+" : "+l
                puts " * "+(File.exists?(v) ? 'use view  ' : 'not found view  ')+" : "+v
            end
            state (@options[:layout].nil? ? :partial : :view)
            @content, mime = e.call v, self if e and File.exists? v
            @mime = mime unless mime.nil?
            state :layout
            @content, mime = e.call l, self if e and File.exists? l
            @mime = mime unless mime.nil?
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
        def no_layout!
            @options[:layout] = nil
        end
        #
        def layout! layout
            @options[:layout] = layout
        end
        #
        def layout
            return '' if @options[:layout].nil?
            File.join(Config.layout_base_path, @options[:layout])+ext
        end
        #
        def static val=nil
            @options[:static] = val if (val==true or val==false)
            return nil if not @options[:static] or @options[:view].nil?
            File.join(Config.static_base_path, @options[:view])+ext
        end
        #
        def view view=nil
            @options[:view] = view unless view.nil? or view.empty?
            return '' if @options[:view].nil?
            File.join(Config.view_base_path, @options[:view])+ext
        end
        #
        def ext ext=nil
            if ext.nil? or ext.empty?
                @options[:ext]||''
            else
                @options[:ext] = (ext[0]=='.' ? (ext.length==1 ? nil : ext) : '.'+ext)
            end
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
