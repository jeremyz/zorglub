# -*- coding: UTF-8 -*-
#
require 'haml/util'
require 'haml/engine'
#
module Zorglub
    module Engines
        module Haml
            def self.proc path,obj
                haml = ::Haml::Engine.new( File.open(path,'r').read, Zorglub::Config.haml_options )
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
