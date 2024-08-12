require 'haml/util'
require 'haml/template'

module Zorglub
  module Engines
    module Haml
      def self.proc(path, obj)
        if obj.app.opt(:engines_cache_enabled)
          key = path.sub obj.app.opt(:root), ''
          haml = obj.app.engines_cache[key] || ::Haml::Template.new(obj.app.opt(:haml_options)) { ::File.read(path) }
        else
          haml = ::Haml::Template.new(obj.app.opt(:haml_options)) { ::File.read(path) }
        end
        html = haml.render(obj)
        [html, 'text/html']
      end
    end
  end
end
