# -*- coding: UTF-8 -*-
#
require 'securerandom'
#
module Zorglub
    #
    Config.session_id_length ||= 64
    Config.session_ttl ||= (60 * 60 * 24 * 5)
    #
    class Session
        #
        def gen_session_id
            SecureRandom.hex Config.session_id_length
        end
        #
    end
    #
end
#
# EOF
