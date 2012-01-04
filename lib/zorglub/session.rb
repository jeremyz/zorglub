# -*- coding: UTF-8 -*-
#
require 'securerandom'
#
module Zorglub
    #
    class Node
        #
        @sessions = {}
        #
        class << self
            attr_reader :sessions
        end
        #
        def session
            @session ||= SessionHash.new @request, @response, Node.sessions
        end
    end
    #
    class SessionHash < Hash
        #
        def initialize req, resp, sessions
            @request = req
            @response = resp
            @sessions = sessions
            @sid = nil
            super()
        end
        #
        def [] key
            load_data!
            super key
        end
        #
        def has_key? key
            load_data!
            super key
        end
        alias :key? :has_key?
        alias :include? :has_key?
        #
        def []= key, value
            load_data!
            super key, value
        end
        #
        def clear
            load_data!
#            @response.delete_cookie Zorglub::Config.session_key
#            @sessions.delete @sid
#            @sid = nil
            super
        end
        #
        def to_hash
            load_data!
            h = {}.replace(self)
            h.delete_if { |k,v| v.nil? }
            h
        end
        #
        def update hash
            load_data!
            super stringify_keys(hash)
        end
        #
        def delete key
            load_data!
            super key
        end
        #
        def inspect
            if loaded?
                super
            else
                "#<#{self.class}:0x#{self.object_id.to_s(16)} not yet loaded>"
            end
        end
        #
        def exists?
            ( loaded? ? @sessions.has_key?(@sid) : false )
        end
        #
        def loaded?
            not @sid.nil?
        end
        #
        def empty?
            load_data!
            super
        end
        #
        private
        #
        def load_data!
            return if loaded?
            if Config.session_on
                sid = @request.cookies[Zorglub::Config.session_key]
                if sid.nil?
                    sid = generate_sid!
                    @response.set_cookie Zorglub::Config.session_key, sid
                end
                replace @sessions[sid] ||={}
                @sessions[sid] = self
                @sid = sid
            end
        end
        #
        def stringify_keys other
            hash = {}
            other.each do |key, value|
                hash[key] = value
            end
            hash
        end
        #
        def generate_sid!
            begin sid = sid_algorithm end while @sessions.has_key? sid
            sid
        end
        #
        begin
            require 'securerandom'
            # Using SecureRandom, optional length.
            # SecureRandom is available since Ruby 1.8.7.
            # For Ruby versions earlier than that, you can require the uuidtools gem,
            # which has a drop-in replacement for SecureRandom.
            def sid_algorithm; SecureRandom.hex(Zorglub::Config.session_sid_len); end
        rescue LoadError
            require 'openssl'
            # Using OpenSSL::Random for generation, this is comparable in performance
            # with stdlib SecureRandom and also allows for optional length, it should
            # have the same behaviour as the SecureRandom::hex method of the
            # uuidtools gem.
            def sid_algorithm
                OpenSSL::Random.random_bytes(Zorglub::Config.session_sid_len / 2).unpack('H*')[0]
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
