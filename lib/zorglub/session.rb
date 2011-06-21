# -*- coding: UTF-8 -*-
#
require 'securerandom'
#
module Zorglub
    #
    class SessionHash
        #
        @data = {}
        class << self
            attr_reader :data
        end
        #
        def initialize sid
            @sid = sid
            # TODO if sid is nil, one should be created
            @session_data = SessionHash.data[sid]||={}
        end
        #
        def exists?
            not @sid.nil?
        end
        #
        def [] idx
            @session_data[idx]
        end
        #
        def []= idx, v
            @session_data[idx] = v
        end
    end
    #
    class Session
        #
        @session_key =  'zorglub.sid'
        @session_kls = Zorglub::SessionHash
        class << self
            attr_accessor :session_key, :session_kls
        end
        #
        def initialize req
            @request = req
            @instance = nil
        end
        #
        def setup!
            if Config.session_on
                @instance = Session.session_kls.new @request.cookies[Session.session_key]
            else
                @instance = {}
            end
        end
        private :setup!
        #
        def exists?
            setup! if @instance.nil?
            @instance.exists?
        end
        #
        def [] idx
            setup! if @instance.nil?
            @instance[idx]
        end
        #
        def []= idx, v
            setup! if @instance.nil?
            @instance[idx] = v
        end
        #
    end
    #
end
#
# EOF
