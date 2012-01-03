# -*- coding: UTF-8 -*-
#
module Zorglub
    #
    class Config
        @options = {
            :root => '.',
            :engine => nil,
            :layout => 'default',
            :view_dir => 'view',
            :layout_dir => 'layout',
            :session_on => false
        }
        @engines = { }
        class << self
            #
            def [] k
                @options[k]
            end
            #
            def []= k, v
                @options[k]=v
            end
            #
            def view_base_path
                if @options.has_key? :view_path
                    @options[:view_path]
                else
                    File.join @options[:root], @options[:view_dir]
                end
            end
            #
            def layout_base_path
                if @options.has_key? :layout_path
                    @options[:layout_path]
                else
                    File.join @options[:root], @options[:layout_dir]
                end
            end
            #
            def register_engine name, ext, proc
                return unless name
                @engines[name]=[ ext, proc ]
            end
            #
            def engine_ext engine
                e = @engines[engine]
                return '' if e.nil?
                x=e[0]
                ( x.nil? ? '' : '.'+x )
            end
            #
            def engine_proc engine
                e = @engines[engine]
                ( e.nil? ? nil : e[1] )
            end
            #
        end
        #
        def self.method_missing m, *args, &block
            if m=~/(.*)=$/
                @options[$1.to_sym]=args[0]
            else
                @options[m.to_sym]
            end
        end
        #
    end
    #
end
#
# EOF
