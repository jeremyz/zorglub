require 'haml/util'
require 'haml/engine'

module Zorglub
  module Engines
    module File
      def self.proc(path, _obj)
        content = ::File.read(path)
        ext = path.sub(/.*\.(.+)$/, '\1')
        [content, "text/#{ext}"]
      end
    end
  end
end
