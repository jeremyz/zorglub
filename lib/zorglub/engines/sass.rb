# -*- coding: UTF-8 -*-
#
require 'sass/util'
require 'sass/engine'
#
module Zorglub
    module Engines
        module Sass
            def self.proc path,obj
                if obj.app.opt(:engines_cache_enabled)
                    key = path.sub obj.app.opt(:root),''
                    sass = obj.app.engines_cache[key] ||= ::Sass::Engine.new( ::File.open(path,'r'){|f| f.read }, obj.app.opt(:sass_options) )
                else
                    sass = ::Sass::Engine.new( ::File.open(path,'r'){|f| f.read }, obj.app.opt(:sass_options) )
                end
                css = sass.render
                return css, 'text/css'
            end
        end
    end
end
#
# EOF
