# -*- coding: UTF-8 -*-
#
require 'spec_helper'
#
def clean_static_path
    static_base_path = Zorglub::Config.static_base_path
    Dir.glob( File.join(static_base_path,'**','*') ).each do |f| File.unlink f if File.file? f end
    Dir.glob( File.join(static_base_path,'*') ).each do |d| Dir.rmdir d end
    Dir.rmdir static_base_path if File.directory? static_base_path
end
#
describe Zorglub do
    #
    describe Zorglub::Node do
        #
        before(:all) do
            clean_static_path
        end
        #
        after(:all) do
            clean_static_path
        end
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
        it "default mime-type should be text/html" do
            r = Node0.my_call '/index'
            r.header['Content-type'].should == 'text/html'
        end
        #
        it "should be able to override mime-type" do
            r = Node0.my_call '/do_render'
            r.header['Content-type'].should == 'text/view'
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
        it "static pages should be generated" do
            r = Node6.my_call '/do_static'
            r.body[0].should == 'VAL 1'
            r.header['Content-type'].should == 'text/static'
            r = Node6.my_call '/do_static'
            r.body[0].should == 'VAL 1'
            r.header['Content-type'].should == 'text/static'
            r = Node6.my_call '/do_static'
            r.body[0].should == 'VAL 1'
            r.header['Content-type'].should == 'text/static'
            r = Node6.my_call '/no_static'
            r.body[0].should == 'VAL 4'
            r.header['Content-type'].should == 'text/static'
        end
        #
        it "redirect should work" do
            r = Node0.my_call '/do_redirect'
            r.status.should == 302
            r.header['location'].should == Node0.r(:do_partial,1,2,3)
        end
        #
        it "no_layout! should be inherited" do
            Node5.layout.should be_nil
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
        #
        it "ext definition and file engine should work" do
            r = Node0.my_call '/xml_file'
            r.body[0].should  == "<xml>file<\/xml>\n"
            r = Node0.my_call '/plain_file'
            r.body[0].should == "plain file\n"
        end
        #
        it "haml engine should work" do
            r = Node0.my_call '/engines/haml'
            r.body[0].should == "<h1>Hello world</h1>\n"
        end
        #
        it "view_base_path! should work" do
            r = Node7.my_call '/view_path'
            h = YAML.load r.body[0]
            h[:view].should == File.join(Zorglub::Config.root, 'alt/do_render')
        end
        #
    end
    #
end
