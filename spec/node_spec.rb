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
        end
        #
        it "layout should return default Node's layout" do
            Node0.layout.should == Zorglub::Config.layout
        end
        #
        it "engine should return class defined Node's engine" do
            Node1.engine.should == "spec-engine-1"
            Node2.engine.should == "spec-engine-2"
        end
        #
        it "layout should return class defined Node's layout" do
            Node1.layout.should == "spec-layout-1"
            Node2.layout.should == "spec-layout-2"
        end
        #
        it "engine should return engine inherited from Node2" do
            Node3.engine.should == "spec-engine-2"
        end
        #
        it "layout should return layout inherited from Node2" do
            Node3.layout.should == "spec-layout-2"
        end
        #
        it "r should build a well formed path" do
            Node1.r(1,'arg2',"some").should == "/spec1/1/arg2/some"
        end
        #
        it "should return err404 response when no method found" do
            Node0.respond_to?('noresponse').should be_false
            r = Node2.call( {'PATH_INFO'=>'/noresponse'} )
            r.status.should == 404
        end
        #
        it "simple method should respond" do
            r = Node0.call( {'PATH_INFO'=>'/hello'} )
            r.status.should == 200
            r.body[0].should == 'world'
        end
        #
    end
    #
end
