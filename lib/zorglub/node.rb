# -*- coding: UTF-8 -*-
#
module Zorglub
    #
    class Node
        #
        UNDEFINED=-1
        #
        # class level engine, layout, static, layout_base_path, view_base_path configuration
        #
        class << self
            #
            attr_reader :static
            #
            def engine! engine
                @engine = engine
            end
            #
            def engine
                @engine = @app.opt(:engine) if @engine==UNDEFINED and @app
                @engine
            end
            #
            def no_layout!
                layout! nil
            end
            #
            def layout! layout
                @layout = layout
            end
            #
            def layout
                @layout = @app.opt(:layout) if @layout==UNDEFINED and @app
                @layout
            end
            #
            def static! val
                @static = ( (val==true or val==false) ? val : false )
            end
            #
            def layout_base_path! path
                @layout_base_path = path
            end
            #
            def layout_base_path
                @layout_base_path ||= @app.layout_base_path
            end
            #
            def view_base_path! path
                @view_base_path = path
            end
            #
            def view_base_path
                @view_base_path ||= @app.view_base_path
            end
        end
        #
        # instance level engine, layout, view, static configuration
        #
        def engine! engine
            @options[:engine] = engine
        end
        #
        def engine
            @options[:engine]
        end
        #
        def no_layout!
            layout! nil
        end
        #
        def layout! layout
            @options[:layout] = layout
        end
        #
        def layout
            return '' if @options[:layout].nil?
            File.join(self.class.layout_base_path, @options[:layout])+ext
        end
        #
        def view! view
            @options[:view] = view
        end
        #
        def view
            return '' if @options[:view].nil?
            File.join(self.class.view_base_path, @options[:view])+ext
        end
        #
        def static! val
            @options[:static] = ((val==true or val==false) ? val : false )
        end
        #
        def static
            return nil if not @options[:static] or @options[:view].nil?
            File.join(app.static_base_path, @options[:view])+ext
        end
        #
        def ext! ext
            @options[:ext]= ( (ext.nil? or ext.empty?) ? nil : (ext[0]=='.' ? (ext.length==1 ? nil : ext) : '.'+ext) )
        end
        #
        def ext
            @options[:ext]||''
        end
        #
        # class level basic node functions
        #
        class << self
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
        end
        #
        # instance level basic node functions
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
        # inherited vars, they can be modified at class level only
        #
        @inherited_vars = { }
        #
        class << self
            #
            attr_reader :inherited_vars
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
        # before_all and after_all hooks
        #
        @inherited_vars[:before_all] = []
        @inherited_vars[:after_all] = []
        class << self
            #
            attr_reader :hooks
            #
            def call_before_hooks obj
                @inherited_vars[:before_all].each do |blk| blk.call obj end
            end
            #
            def before_all &blk
                @inherited_vars[:before_all]<< blk
                @inherited_vars[:before_all].uniq!
            end
            #
            def call_after_hooks obj
                @inherited_vars[:after_all].each do |blk| blk.call obj end
            end
            #
            def after_all &blk
                @inherited_vars[:after_all]<< blk
                @inherited_vars[:after_all].uniq!
            end
            #
        end
        #
        # rack entry point, page computation methods
        #
        class << self
            #
            def inherited sub
                sub.engine! engine||(self==Zorglub::Node ? UNDEFINED : nil )
                sub.layout! layout||(self==Zorglub::Node ? UNDEFINED : nil )
                sub.instance_variable_set :@inherited_vars, {}
                @inherited_vars.each do |s,v| sub.inherited_var s, *v end
            end
            #
            def call env
                meth, *args =  env['PATH_INFO'].sub(/^\//,'').split(/\//)
                meth||= 'index'
                puts "=> #{meth}(#{args.join ','})" if app.opt :debug
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
            def error_404 node
                puts " !! method not found" if app.opt :debug
                resp = node.response
                resp.status = 404
                resp['Content-Type'] = 'text/plain'
                resp.write "%s mapped at %p can't respond to : %p" % [ node.class.name, node.map, node.request.env['PATH_INFO'] ]
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
        def state state=nil
            @options[:state] = state unless state.nil?
            @options[:state]
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
            self.class.call_before_hooks self
            state :meth
            @content = self.send @options[:method], *@options[:args]
            static_path = static
            if static_path.nil?
                compile_page!
            else
                static_page! static_path
            end
            state :post_cb
            self.class.call_after_hooks self
            state :finished
            return @content, @mime
        end
        #
        def static_page! path
            if not File.exists? path
                compile_page!
                Dir.mkdir app.static_base_path
                Dir.mkdir File.dirname path
                File.open(path, 'w') {|f| f.write("@mime:"+@mime+"\n"); f.write(@content); }
                puts " * cache file created : #{path}" if app.opt :debug
            else
                puts " * use cache file : #{path}" if app.opt :debug
                content = File.open(path, 'r') {|f| f.read }
                @content = content.sub /^@mime:(.*)\n/,''
                @mime = $1
            end
        end
        #
        def compile_page!
            e, @options[:ext] = app.engine_proc_ext @options[:engine], @options[:ext]
            v, l, debug = view, layout, app.opt(:debug)
            puts " * "+(File.exists?(l) ? 'use layout' : 'not found layout')+" : "+l if debug
            puts " * "+(File.exists?(v) ? 'use view  ' : 'not found view  ')+" : "+v if debug
            state (@options[:layout].nil? ? :partial : :view)
            @content, mime = e.call v, self if e and File.exists? v
            @mime = mime unless mime.nil?
            state :layout
            @content, mime = e.call l, self if e and File.exists? l
            @mime = mime unless mime.nil?
        end
        #
    end
    #
end
#
# EOF
