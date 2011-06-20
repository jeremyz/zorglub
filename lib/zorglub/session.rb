# -*- coding: UTF-8 -*-
#
require 'securerandom'
#
module Zorglub
    #
    class Session
        #
        @session_key =  'zorglub.sid'
        @session_data = {}
        class << self
            attr_reader :session_key, :session_data
        end
        #
        def initialize cookies
            @sid = cookies[self.class.session_key]
            @data = self.class.session_data[@sid]||={}
        end
        #
        def exists?
            not @sid.nil?
        end
        #
        def [] idx
            @data[idx]
        end
        #
        def []= idx, v
            @data[idx] = v
        end
        #
    end
    #
end
#
# EOF
