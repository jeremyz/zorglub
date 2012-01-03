# -*- coding: UTF-8 -*-
#
require 'spec_helper'
#
describe Zorglub do
    #
    describe Zorglub::Node do
        #
        it "engine should return default Node's engine" do
            Node0.engine.should == Zorglub::Config.engine
            Node0.engine.should == Zorglub::Config[:engine]
        end
        #
        it "layout should return default Node's layout" do
            Node0.layout.should == Zorglub::Config.layout
        end
        #
        it "engine should return class defined Node's engine" do
            Node1.engine.should == "engine-1"
            Node3.engine.should == "engine-2"
        end
        #
        it "layout should return class defined Node's layout" do
            Node1.layout.should == "layout-1"
            Node3.layout.should == "layout-2"
        end
        #
        it "engine should return engine inherited from Node2" do
            Node2.engine.should == "engine-1"
        end
        #
        it "layout should return layout inherited from Node2" do
            Node2.layout.should == "layout-1"
        end
        #
        it "r should build a well formed path" do
            Node1.r(1,'arg2',"some").should == "/spec1/1/arg2/some"
        end
        #
        it "should return err404 response when no method found" do
            Node0.respond_to?('noresponse').should be_false
            r = Node0.call( {'PATH_INFO'=>'/noresponse'} )
            r.status.should == 404
        end
        #
        it "simple method should respond" do
            r = Node0.call( {'PATH_INFO'=>'/hello'} )
            r.status.should == 200
            r.body[0].should == 'world'
        end
        #
        it "arguments should work" do
            r = Node0.call( {'PATH_INFO'=>'/with_2args/1/2'} )
            h = YAML.load r.body[0]
            h[:args][0].should == '1'
            h[:args][1].should == '2'
        end
        #
        it "should raise error when too much arguments" do
            lambda{ r = Node0.call( {'PATH_INFO'=>'/with_2args/1/2/3'} ) }.should raise_error ArgumentError
        end
        #
        it "layout proc, method level layout and engine definitions should work" do
            r = Node0.call( {'PATH_INFO'=>'/index'} )
            r.status.should == 200
            h = YAML.load r.body[0]
            ly = File.join Zorglub::Config.root, Zorglub::Config.layout_dir, Node0.layout
            vu = File.join Zorglub::Config.root, Zorglub::Config.view_dir, Node0.r, 'index'
            h[:path].should == ly
            h[:layout].should == ly
            h[:view].should == vu
        end
        #
        it "layout proc, method level layout and engine definitions should work" do
            r = Node1.call( {'PATH_INFO'=>'/index'} )
            r.status.should == 200
            h = YAML.load r.body[0]
            ly = File.join Zorglub::Config.root, Zorglub::Config.layout_dir, 'main.spec'
            vu = File.join Zorglub::Config.root, Zorglub::Config.view_dir, Node1.r, 'index.spec'
            h[:path].should == ly
            h[:layout].should == ly
            h[:view].should == vu
        end
        #
        it "before_all hook should work" do
            Node3.before = 0
            Node3.after = 0
            Node3.before.should == 0
            Node3.call( {'PATH_INFO'=>'/index'} )
            Node3.before.should == 1
            Node3.call( {'PATH_INFO'=>'/index'} )
            Node3.before.should == 2
            Node3.call( {'PATH_INFO'=>'/index'} )
            Node3.before.should == 3
        end
        #
        it "after_all hook should work" do
            Node3.before = 0
            Node3.after = 0
            Node3.after.should == 0
            Node3.call( {'PATH_INFO'=>'/index'} )
            Node3.after.should == 1
            Node3.call( {'PATH_INFO'=>'/index'} )
            Node3.after.should == 2
            Node3.call( {'PATH_INFO'=>'/index'} )
            Node3.after.should == 3
        end
    end
    #
end
