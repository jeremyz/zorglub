# -*- coding: UTF-8 -*-
#
require 'haml/util'
require 'haml/engine'
#
module Zorglub
    module Engines
        module Haml
            def self.proc path,obj
                if Zorglub::Config.engines_cache_enabled
                    key = path.sub Zorglub::Config.root,''
                    haml = obj.app.engines_cache[key] ||= ::Haml::Engine.new( File.open(path,'r').read, Zorglub::Config.haml_options )
                else
                    haml = ::Haml::Engine.new( File.open(path,'r').read, Zorglub::Config.haml_options )
                end
                html = haml.render(obj)
                return html, 'text/html'
            end
        end
    end
end
#
Zorglub::Config.register_engine :haml, 'haml', Zorglub::Engines::Haml.method(:proc)
#
# EOF
