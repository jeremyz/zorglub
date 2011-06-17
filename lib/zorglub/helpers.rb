# -*- coding: UTF-8 -*-
#
module Zorglub
    #
    module Helpers
        #
        module Js
            def self.included mod
                # class level instance variables
                mod.instance_variable_set :@js, []
                # class accessors
                def mod.js *args
                    unless args.empty?
                        @js.concat args
                        @js.uniq!
                    end
                    @js
                end
            end
            # instance accessor
            def js *args
                @js ||=self.class.js.clone
                unless args.empty?
                    @js.concat args
                    @js.uniq!
                end
                @js
            end
            #
        end
        #
        module Css
            def self.included mod
                # class level instance variables
                mod.instance_variable_set :@css, []
                # class accessors
                def mod.css *args
                    unless args.empty?
                        @css.concat args
                        @css.uniq!
                    end
                    @css
                end
            end
            # instance accessor
            def css *args
                @css ||=self.class.css.clone
                unless args.empty?
                    @css.concat args
                    @css.uniq!
                end
                @css
            end
            #
        end
    end
    #
end
#
# EOF
