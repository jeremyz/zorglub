require 'fileutils'

module Zorglub
  class Node
    UNDEFINED = -1

    # class level engine, layout, static, layout_base_path, view_base_path configuration

    class << self
      attr_reader :static, :cache_lifetime

      def engine!(engine)
        @engine = engine
      end

      def engine
        @engine = @app.opt(:engine) if @engine == UNDEFINED && @app
        @engine
      end

      def no_layout!
        layout! nil
      end

      def layout!(layout)
        @layout = layout
      end

      def layout
        @layout = @app.opt(:layout) if @layout == UNDEFINED && @app
        @layout
      end

      def static!(val, lifetime = 0)
        @static = [true, false].include?(val) ? val : false
        @cache_lifetime = lifetime
      end

      def layout_base_path!(path)
        @layout_base_path = path
      end

      def layout_base_path
        @layout_base_path ||= @app.layout_base_path
      end

      def view_base_path!(path)
        @view_base_path = path
      end

      def view_base_path
        @view_base_path ||= @app.view_base_path
      end
    end

    # instance level engine, layout, view, static configuration

    def engine!(engine)
      @engine = engine
    end

    def no_layout!
      layout! nil
    end

    def layout!(layout)
      @layout = layout
    end

    def layout
      return nil if @layout.nil?

      File.join(self.class.layout_base_path, @layout) + ext
    end

    def no_view!
      view! nil
    end

    def view!(view)
      @view = view
    end

    def view
      return nil if @view.nil?

      File.join(self.class.view_base_path, @view) + ext
    end

    def static!(val, lifetime = 0)
      @static = [true, false].include?(val) ? val : false
      @cache_lifetime = lifetime
    end

    def static
      return nil if !@static || @view.nil?

      File.join(app.static_base_path, @view) + ext
    end

    def ext!(ext)
      @ext = if ext.nil? || ext.empty?
               nil
             elsif ext[0] == '.'
               ext.length == 1 ? nil : ext
             else
               ".#{ext}"
             end
    end

    def ext
      @ext || ''
    end

    def mime!(mime)
      @mime = mime
    end

    # class level basic node functions

    class << self
      attr_accessor :app

      def map(app, location)
        @app = app
        @app.map location, self
      end

      def r *args
        @r ||= @app.to self
        args.empty? ? @r : File.join(@r, args.map(&:to_s))
      end
    end

    # instance level basic node functions

    def app
      self.class.app
    end

    def map
      self.class.r
    end

    def r *args
      File.join map, (args.empty? ? meth : args.map(&:to_s))
    end

    def partial(meth, *args, **options)
      self.class.partial(meth, *args, env: request.env, parent: self, **options)
    end

    def html
      %i[map r args engine layout view].inject('') { |s, sym| s + "<p>#{sym} => #{send sym}</p>" }
    end

    def redirect(target, options = {}, &block)
      status = options[:status] || 302
      body   = options[:body] || redirect_body(target)
      header = response.headers.merge('Location' => target.to_s)
      throw :stop_realize, Rack::Response.new(body, status, header, &block)
    end

    def redirect_body(target)
      "You are being redirected, please follow this link to: <a href='#{target}'>#{target}</a>!"
    end

    # class level inherited values are key=>array, copied at inheritance
    # so they can be extanded at class level
    # values are copied from class into instance at object creation
    # so that can be extanded without modifying class level values
    # typical usage are css or js inclusions

    @cli_vals = {}

    class << self
      attr_reader :cli_vals

      def cli_val(sym, *args)
        vals = @cli_vals[sym] ||= []
        unless args.empty?
          vals.concat args
          vals.uniq!
        end
        vals
      end
    end

    def cli_val(sym, *args)
      vals = @cli_vals[sym] ||= []
      unless args.empty?
        vals.concat args
        vals.uniq!
      end
      vals
    end

    # before_all and after_all hooks

    @cli_vals[:before_all] = []
    @cli_vals[:after_all] = []
    class << self
      def call_before_hooks(obj)
        @cli_vals[:before_all].each { |blk| blk.call obj }
      end

      def before_all(meth = nil, &blk)
        @cli_vals[:before_all] << (meth.nil? ? blk : meth)
        @cli_vals[:before_all].uniq!
      end

      def call_after_hooks(obj)
        @cli_vals[:after_all].each { |blk| blk.call obj }
      end

      def after_all(meth = nil, &blk)
        @cli_vals[:after_all] << (meth.nil? ? blk : meth)
        @cli_vals[:after_all].uniq!
      end
    end

    # rack entry point, page computation methods

    class << self
      def inherited(sub)
        super
        sub.engine!(engine || (self == Zorglub::Node ? UNDEFINED : nil))
        sub.layout!(layout || (self == Zorglub::Node ? UNDEFINED : nil))
        sub.instance_variable_set :@cli_vals, {}
        @cli_vals.each { |s, v| sub.cli_val s, *v }
      end

      def call(env)
        meth, *args =  env['PATH_INFO'].sub(%r{^/+}, '').split(%r{/})
        meth ||= 'index'
        $stdout << "=> #{meth}(#{args.join ','})\n" if app.opt :debug
        node = new(env, meth, args)
        return error404(node, meth) unless node.respond_to?(meth)

        node.realize!
      end

      def partial(meth, *args, **options)
        node = new(options[:env] || {}, meth, args, partial: true, **options)
        return error404(node, meth) unless meth.nil? || node.respond_to?(meth)

        node.feed!(no_hooks: options[:no_hooks] || false)
        node.content
      end

      def error404(node, meth)
        $stdout << " !! #{node.class.name}::#{meth} not found\n" if app.opt :debug
        resp = node.response
        resp.status = 404
        resp['content-type'] = 'text/plain'
        resp.write "#{node.class.name} mapped at #{node.map} can't respond to : #{node.meth}"
        resp.finish
      end
    end

    attr_reader :request, :response, :content, :mime, :state, :engine, :meth, :args, :depth, :parent

    def initialize(env, meth, args, **options)
      @parent = options[:parent]
      @depth = @parent ? @parent.depth + 1 : 0
      raise 'Recursive partial depth limit exceeded' if @depth > 20

      @debug = app.opt :debug
      @static = self.class.static
      @engine = self.class.engine
      @cache_lifetime = self.class.cache_lifetime

      @meth = meth.to_s
      @args = args
      @request = @parent ? @parent.request : Rack::Request.new(env)
      @response = @parent ? @parent.response : Rack::Response.new

      @view = options[:view] || r(@meth)
      @partial = options[:partial] || false
      @layout = (options[:partial] ? nil : self.class.layout)

      @cli_vals = {}
      self.class.cli_vals.each { |s, v| cli_val s, *v }

      (options[:locals] || {}).each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end

    def realize!
      catch(:stop_realize) do
        feed!
        response.write @content
        response.headers['content-type'] ||= @mime || 'text/html'
        response
      end.finish
    end

    def feed!(no_hooks: false)
      @state = :pre_cb
      self.class.call_before_hooks self unless no_hooks
      @state = :meth
      @content = send(@meth, *@args) unless @meth.empty?
      if (static_path = static)
        static_page! static_path
      else
        compile_page!
      end
      @state = :post_cb
      self.class.call_after_hooks self unless no_hooks
      @state = :finished
      [@content, @mime]
    end

    def static_page!(path)
      if File.exist?(path) && (@cache_lifetime.nil? || @cache_lifetime.zero? ||
          (Time.now - File.stat(path).mtime) < @cache_lifetime)
        $stdout << " * use cache file : #{path}\n" if @debug
        content = File.read(path)
        @content = content.sub(/^@mime:(.*)\n/, '')
        @mime = ::Regexp.last_match(1)
      else
        compile_page!
        FileUtils.mkdir_p File.dirname(path)
        File.open(path, 'w') { |f| f.write("@mime:#{@mime}\n#{@content}") }
        $stdout << " * cache file created : #{path}\n" if @debug
      end
    end

    def compile_page!
      e, @ext = app.engine_proc_ext @engine, @ext
      v = view
      l = layout
      if @debug
        $stdout << " * #{e ? 'use engine' : 'no engine '} : #{e ? e.to_s : ''}\n"
        $stdout << " * #{l && File.exist?(l) ? 'use layout' : 'no layout '} : #{l || ''}\n"
        $stdout << " * #{v && File.exist?(v) ? 'use view  ' : 'no view   '} : #{v || ''}\n"
      end
      @state = @partial ? :partial : :view
      @content, mime = e.call(v, self) if e && v && File.exist?(v)
      @mime ||= mime
      @state = :layout
      @content, mime = e.call(l, self) if e && l && File.exist?(l)
      @mime = mime if @mime.nil? && !mime.nil?
    end
  end
end
