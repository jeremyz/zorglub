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
            :session_on => false,
            :session_key => 'zorglub.sid',
            :session_secret => 'session-secret-secret',
            :session_sid_len => 64,
            :haml_options => {
                :format => :html5,
                :ugly => false,
                :encoding => 'utf-8'
            }
        #
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
                p = @options[:view_path]
                ( p.nil? ? File.join(@options[:root], @options[:view_dir]) : p )
            end
            #
            def layout_base_path
                p = @options[:layout_path]
                ( p.nil? ? File.join(@options[:root], @options[:layout_dir]) : p )
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
