# -*- coding: UTF-8 -*-
#
module Zorglub
    #
    class Config
        @options = {
            :debug => false,
            :root => '.',
            :engine => nil,
            :layout => 'default',
            :view_dir => 'view',
            :layout_dir => 'layout',
            :static_dir => 'static',
            :session_on => false,
            :session_key => 'zorglub.sid',
            :session_secret => 'session-secret-secret',
            :session_sid_len => 64,
            :engines_cache_enabled => true,
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
            def static_base_path
                p = @options[:static_path]
                ( p.nil? ? File.join(@options[:root], @options[:static_dir]) : p )
            end
            #
            def register_engine name, ext, proc
                return unless name
                if ext.nil? or ext.empty?
                    x = nil
                else
                    x = (ext[0]=='.' ? (ext.length==1 ? nil : ext) : '.'+ext)
                end
                @engines[name]=[ proc, x ]
            end
            #
            def engine_proc_ext engine, ext
                p,x = @engines[engine]
                return [nil, ''] if p.nil?
                [ p, ((ext.nil? or ext.empty?) ? x : ext ) ]
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
