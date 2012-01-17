# -*- coding: UTF-8 -*-
#
require 'haml/util'
require 'haml/engine'
#
module Zorglub
    module Engines
        module File
            def self.proc path,obj
                content = ::File.open(path,'r'){|f| f.read }
                ext = path.sub /.*\.(.+)$/,'\1'
                return content, "text/#{ext}"
            end
        end
    end
end
#
# EOF
