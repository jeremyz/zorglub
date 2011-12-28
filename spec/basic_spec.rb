# -*- coding: UTF-8 -*-
#
require 'spec_helper'
#
describe Zorglub do
    #
    describe Zorglub::App do
        #
        it "map should add a mapped node" do
            APP.at("/temp").should be_nil
            APP.map "/temp", Temp
            APP.at("/temp").should be Temp
        end
        #
        it "delete should delete a mapped node" do
            APP.at("/temp").should be Temp
            APP.delete "/temp"
            APP.at("/temp").should be_nil
        end
        #
        it "at should return mapped node" do
            APP.at("/spec1").should be Node1
        end
        #
        it "at should return nil if no Node mapped" do
            APP.at("/none").should be_nil
        end
        #
        it "to should return path to node" do
            APP.to(Node1).should == "/spec1"
        end
        #
        it "to should return nil if not an existing Node" do
            APP.to(nil).should be_nil
        end
        #
        it "to_hash should return a correct hash" do
            APP.to_hash["/spec1"].should be Node1
        end
        #
    end
    #
    describe Zorglub::Node do
        #
        it "engine should return Node's engine" do
            Node1.engine.should == Zorglub::Config.engine
            Node2.engine.should == "spec-engine-2"
        end
        #
        it "layout should return Node's layout" do
            Node1.layout.should == Zorglub::Config.layout
            Node2.layout.should == "spec-layout-2"
        end
        #
        it "r should build a well formed path" do
            Node1.r(1,'arg2',"some").should == "/spec1/1/arg2/some"
        end
        #
    end
    #
end
