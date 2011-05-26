#! /usr/bin/ruby
#
$LOAD_PATH << File.join(File.dirname( File.absolute_path(__FILE__)), '..', 'lib')
#
require 'zorglub'
#
class Node1 < Zorglub::Node
    #
    def index a1, *a2
        response.write "<title>Node1</title>"
        response.write "<p>a1 : #{a1.inspect}</p>"
        response.write "<p>a2 : #{a2.inspect}</p>"
        response.finish
    end
    #
end
#
APP = Zorglub::App.new do
    map '/url1', Node1
end
#
class Node2 < Zorglub::Node
    #
    map APP, '/url2'
    #
    def index a1, *a2
        response.write "<title>Node2</title>"
        response.write "<p>a1 : #{a1.inspect}</p>"
        response.write "<p>a2 : #{a2.inspect}</p>"
        response.finish
    end
    #
end
#
puts APP.to_hash.inspect
#
map '/' do
    use Rack::ShowExceptions
    run APP
end
#
