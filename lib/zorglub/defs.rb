# -*- coding: UTF-8 -*-
#
module Zorglub
    #
    class Node
        #
        @defs_h = {
        }
        #
        class << self
            #
            attr_reader :defs_h
            #
            # TODO override is maybe not the better way
            def inherited sub
                sub.layout layout
                sub.engine engine
                sub.instance_variable_set :@defs_h, {}
                @defs_h.each do |d,v|
                    sub.defs d, *v
                end
            end
            #
            def defs sym, *args
                unless args.empty?
                    @defs_h[sym] ||=[]
                    @defs_h[sym].concat args
                    @defs_h[sym].uniq!
                end
                @defs_h[sym]
            end
            #
        end
        #
        def defs sym, *args
            d = self.class.defs_h[sym].clone
            unless args.empty?
                d ||=[]
                d.concat args
                d.uniq!
            end
            d
        end
    end
    #
end
#
# EOF
