require 'securerandom'

module Zorglub
  class Node
    @sessions = {}

    class << self
      attr_reader :sessions
    end

    def session
      @session ||= SessionHash.new @request, @response, Node.sessions, app.opt(:session_options)
    end
  end

  class SessionHash < Hash
    def initialize(req, resp, sessions, options)
      @request = req
      @response = resp
      @sessions = sessions
      @sid = nil
      @options = options
      super()
    end

    def [](key)
      load_data!
      super key
    end

    def key?(key)
      load_data!
      super key
    end
    alias include? key?

    def []=(key, value)
      load_data!
      super key, value
    end

    def clear
      load_data!
      # @response.delete_cookie @options[:key]
      # @sessions.delete @sid
      # @sid = nil
      super
    end

    def to_hash
      load_data!
      h = {}.replace(self)
      h.delete_if { |_k, v| v.nil? }
      h
    end

    def update(hash)
      load_data!
      super stringify_keys(hash)
    end

    def delete(key)
      load_data!
      super key
    end

    def inspect
      if loaded?
        super
      else
        "#<#{self.class}:0x#{object_id.to_s(16)} not yet loaded>"
      end
    end

    def exists?
      loaded? ? @sessions.key?(@sid) : false
    end

    def loaded?
      !@sid.nil?
    end

    def empty?
      load_data!
      super
    end

    private

    def load_data!
      return if loaded?
      return unless @options[:enabled]

      sid = @request.cookies[@options[:key]]
      if sid.nil?
        sid = generate_sid!
        @response.set_cookie @options[:key], sid
      end
      replace @sessions[sid] ||= {}
      @sessions[sid] = self
      @sid = sid
    end

    def stringify_keys(other)
      hash = {}
      other.each do |key, value|
        hash[key] = value
      end
      hash
    end

    def generate_sid!
      loop do
        sid = SecureRandom.hex(@options[:sid_len])
        break unless @sessions.key?(sid)
      end
      sid
    end
  end
end
