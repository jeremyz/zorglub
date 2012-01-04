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
            Node1.r(1,'arg2',"some").should == "/node1/1/arg2/some"
        end
        #
        it "instance level map should work" do
            r = Node0.my_call '/with_2args/1/2'
            h = YAML.load r.body[0]
            h[:map].should == '/node0'
        end
        #
        it "should return err404 response when no method found" do
            Node0.respond_to?('noresponse').should be_false
            r = Node0.my_call '/noresponse'
            r.status.should == 404
        end
        #
        it "simple method should respond" do
            r = Node0.my_call '/hello'
            r.status.should == 200
            r.body[0].should == 'world'
        end
        #
        it "instance level args should work" do
            r = Node0.my_call '/with_2args/1/2'
            h = YAML.load r.body[0]
            h[:args][0].should == '1'
            h[:args][1].should == '2'
        end
        #
        it "should raise error when too much arguments" do
            lambda{ r = Node0.my_call '/with_2args/1/2/3' }.should raise_error ArgumentError
        end
        #
        it "layout proc, method level layout and engine definitions should work" do
            r = Node0.my_call '/index'
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
            r = Node1.my_call '/index'
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
            Node3.my_call '/index'
            Node3.before.should == 1
            Node3.my_call '/index'
            Node3.before.should == 2
            Node3.my_call '/index'
            Node3.before.should == 3
        end
        #
        it "after_all hook should work" do
            Node3.before = 0
            Node3.after = 0
            Node3.after.should == 0
            Node3.my_call '/index'
            Node3.after.should == 1
            Node3.my_call '/index'
            Node3.after.should == 2
            Node3.my_call '/index'
            Node3.after.should == 3
        end
        #
        it "should find view and layout and render them" do
            r = Node0.my_call '/do_render'
            r.status.should == 200
            r.body[0].should == "layout_start view_content layout_end"
        end
        #
        it "partial should render correctly" do
            Node0.partial(:do_partial, 1, 2).should == 'partial_content'
        end
        #
        it "method level view should work" do
            Node0.partial(:other_view).should == 'partial_content'
        end
        #
        it "redirect should work" do
            r = Node0.my_call '/do_redirect'
            r.status.should == 302
            r.header['location'].should == Node0.r(:do_partial,1,2,3)
        end
        #
        it "inherited_vars should be inherited and extended" do
            r = Node5.my_call '/index'
            vars = YAML.load r.body[0]
            vars.should == ['js0','js1','js3','jsx','css0','css1','css2']
            vars[7].should be_nil
        end
        #
        it "inherited_vars should be extended at method level" do
            r = Node4.my_call '/more'
            vars = YAML.load r.body[0]
            vars.should == ['js0','js1','js2']
            vars[3].should be_nil
        end
        #
        it "inherited_vars should be untouched" do
            r = Node4.my_call '/index'
            vars = YAML.load r.body[0]
            vars.should == ['js0','js1']
            vars[2].should be_nil
        end
    end
    #
end
