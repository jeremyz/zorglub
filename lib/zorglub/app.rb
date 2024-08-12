require 'rack'

module Zorglub
  class App < Rack::URLMap
    def initialize(map = {}, &block)
      super
      @map = map
      @engines_cache = {}
      @options = {
        debug: false,
        root: '.',
        layout: 'default',
        view_dir: 'view',
        layout_dir: 'layout',
        static_dir: 'static',
        engine: nil,
        engines_cache_enabled: true,
        engines: {},
        haml_options: {
          format: :html5,
          encoding: 'utf-8',
          escape_html: false
        },
        sass_options: {
          syntax: :scss,
          cache: false,
          style: :compressed
        },
        session_options: {
          enabled: false,
          key: 'zorglub.sid',
          secret: 'session-secret-secret',
          sid_len: 64
        }
      }
      instance_eval(&block) if block_given?
      remap @map
    end

    attr_reader :engines_cache

    def map(location, object)
      return unless location && object
      raise StandardError, "#{@map[location]} already mapped to #{location}" if @map.key? location

      object.app = self
      @map.merge! location.to_s => object
      remap @map
    end

    def delete(location)
      @map.delete location
      remap @map
    end

    def at(location)
      @map[location]
    end

    def to(object)
      @map.invert[object]
    end

    def to_hash
      @map.dup
    end

    # OPTIONS @options

    def opt(sym)
      @options[sym]
    end

    def opt!(sym, val)
      @options[sym] = val
    end

    def register_engine!(name, ext, proc)
      x = if ext.nil? || ext.empty?
            nil
          elsif ext[0] == '.'
            ext.length == 1 ? nil : ext
          else
            ".#{ext}"
          end
      @options[:engines][name] = [proc, x]
    end

    def engine_proc_ext(engine, ext)
      p, x = @options[:engines][engine]
      return [nil, ''] if p.nil?

      [p, ext.nil? || ext.empty? ? x : ext]
    end

    def view_base_path
      _base_path @options[:view_path], :view_dir
    end

    def layout_base_path
      _base_path @options[:layout_path], :layout_dir
    end

    def static_base_path
      _base_path @options[:static_path], :static_dir
    end

    private

    def _base_path(path, sym)
      path.nil? ? File.join(@options[:root], @options[sym]) : path
    end
  end
end
