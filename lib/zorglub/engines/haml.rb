# -*- coding: UTF-8 -*-
#
require 'haml/util'
require 'haml/engine'
#
module Zorglub
    module Engines
        module Haml
            def self.proc path,obj
                if obj.app.opt(:engines_cache_enabled)
                    key = path.sub obj.app.opt(:root),''
                    haml = obj.app.engines_cache[key] ||= ::Haml::Engine.new( ::File.open(path,'r'){|f| f.read }, obj.app.opt(:haml_options) )
                else
                    haml = ::Haml::Engine.new( ::File.open(path,'r'){|f| f.read }, obj.app.opt(:haml_options) )
                end
                html = haml.render(obj)
                return html, 'text/html'
            end
        end
    end
end
#
# EOF
