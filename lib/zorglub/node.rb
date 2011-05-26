#! /usr/bin/ruby
#
module Zorglub
    #
    class Node
        #
        class << self
            #
            attr_reader :map
            def map app, location
                @app = app
                @app.map location, self
            end
            #
            def r
                @r ||= @app.to self
            end
            #
            def call env
                node = self.new Rack::Request.new(env), Rack::Response.new
                meth, *args =  env['PATH_INFO'][1..-1].split '/'
                meth||= 'index'
                return error_404 node if not node.respond_to? meth
                # TODO use layout
                # TODO use view
                # TODO session
                node.send meth, *args
            end
            #
            def error_404 node
                resp = node.response
                resp.status = 404
                resp['Content-Type'] = 'text/plain'
                resp.write "%s mapped at %p can't respond to : %p" % [ node.class.name, node.r, node.request.env['PATH_INFO'] ]
                resp
            end
            #
        end
        #
        attr_reader :request, :response
        #
        def initialize req, res
            @request = req
            @response = res
        end
        #
        def r
            self.class.r
        end
        #
    end
    #
end
#
