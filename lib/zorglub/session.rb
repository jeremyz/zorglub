# -*- coding: UTF-8 -*-
#
require 'securerandom'
#
module Zorglub
    #
    class Node
        #
        def session
            @session ||= Session.new @request, @response
        end
    end
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
        @key =  'zorglub.sid'
        @kls = Zorglub::SessionHash
        @sid_length = 64
        #
        class << self
            attr_accessor :key, :kls, :sid_length
        end
        #
        def initialize req, resp
            @request = req
            @response = resp
            @instance = nil
        end
        #
        def setup!
            if Config.session_on
                cookie = @request.cookies[Session.key]
                if cookie.nil?
                    cookie = generate_sid
                    @response.set_cookie Session.key, cookie
                end
                @instance = Session.kls.new cookie
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
        def generate_sid
            begin sid = sid_algorithm end while Session.kls.sid_exists? sid
            sid
        end
        #
        begin
            require 'securerandom'
            # Using SecureRandom, optional length.
            # SecureRandom is available since Ruby 1.8.7.
            # For Ruby versions earlier than that, you can require the uuidtools gem,
            # which has a drop-in replacement for SecureRandom.
            def sid_algorithm; SecureRandom.hex(Session.sid_length); end
        rescue LoadError
            require 'openssl'
            # Using OpenSSL::Random for generation, this is comparable in performance
            # with stdlib SecureRandom and also allows for optional length, it should
            # have the same behaviour as the SecureRandom::hex method of the
            # uuidtools gem.
            def sid_algorithm
                OpenSSL::Random.random_bytes(Session.sid_length / 2).unpack('H*')[0]
            end
        rescue LoadError
            # Digest::SHA2::hexdigest produces a string of length 64, although
            # collisions are not very likely, the entropy is still very low and
            # length is not optional.
            #
            # Replacing it with OS-provided random data would take a lot of code and
            # won't be as cross-platform as Ruby.
            def sid_algorithm
                entropy = [ srand, rand, Time.now.to_f, rand, $$, rand, object_id ]
                Digest::SHA2.hexdigest(entropy.join)
            end
        end
        #
    end
    #
end
#
# EOF
