require 'sass'

module Zorglub
  module Engines
    module Sass
      def self.proc(path, obj)
        sass = ::Sass::Engine.new(::File.read(path), obj.app.opt(:sass_options))
        if obj.app.opt(:engines_cache_enabled)
          key = path.sub obj.app.opt(:root), ''
          obj.app.engines_cache[key] ||= sass
        end
        css = sass.render
        [css, 'text/css']
      end
    end
  end
end
