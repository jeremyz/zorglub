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
            APP.at("/node1").should be Node1
        end
        #
        it "at should return nil if no Node mapped" do
            APP.at("/none").should be_nil
        end
        #
        it "to should return path to node" do
            APP.to(Node1).should == "/node1"
        end
        #
        it "to should return nil if not an existing Node" do
            APP.to(nil).should be_nil
        end
        #
        it "to_hash should return a correct hash" do
            APP.to_hash["/node1"].should be Node1
        end
        #
    end
    #
end
