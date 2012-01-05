# -*- coding: UTF-8 -*-
#
require 'rack'
#
module Zorglub
    #
    class App < Rack::URLMap
        #
        def initialize map={}, &block
            super
            @map = map
            instance_eval &block if block_given?
            remap @map
            @engines_cache = { }
        end
        attr_reader :engines_cache
        #
        def map location, object
            return unless location and object
            raise Exception.new "#{@map[location]} already mapped to #{location}" if @map.has_key? location
            object.app = self
            @map.merge! location.to_s=>object
            remap @map
        end
        #
        def delete location
            @map.delete location
            remap @map
        end
        #
        def at location
            @map[location]
        end
        #
        def to object
            @map.invert[object]
        end
        #
        def to_hash
            @map.dup
        end
        #
    end
    #
end
#
# EOF
