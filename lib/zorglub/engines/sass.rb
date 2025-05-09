require 'sass'

module Zorglub
  module Engines
    module Sass
      def self.proc(path, obj)
        if obj.app.opt(:engines_cache_enabled)
          key = path.sub obj.app.opt(:root), ''
          sass = obj.app.engines_cache[key] || ::Sass::Engine.new(::File.read(path), obj.app.opt(:sass_options))
        else
          sass = ::Sass::Engine.new(::File.read(path), obj.app.opt(:sass_options))
        end
        css = sass.render
        [css, 'text/css']
      end
    end
  end
end
