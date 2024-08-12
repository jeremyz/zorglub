require 'haml/util'
require 'haml/template'

module Zorglub
  module Engines
    module Haml
      def self.proc(path, obj)
        haml = ::Haml::Template.new(path)
        if obj.app.opt(:engines_cache_enabled)
          key = path.sub obj.app.opt(:root), ''
          obj.app.engines_cache[key] ||= haml
        end
        html = haml.render(obj, obj.app.opt(:haml_options))
        [html, 'text/html']
      end
    end
  end
end
