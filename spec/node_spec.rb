require 'spec_helper'

def clean_static_path
  static_base_path = Node0.app.static_base_path
  Dir.glob(File.join(static_base_path, '**', '*')).each { |f| File.unlink f if File.file? f }
  Dir.glob(File.join(static_base_path, '*')).each { |d| Dir.rmdir d }
  Dir.rmdir static_base_path if File.directory? static_base_path
end

describe Zorglub do
  describe Zorglub::Node do
    before(:all) do
      clean_static_path
    end

    after(:all) do
      clean_static_path
    end

    it "engine should return default Node's engine" do
      expect(Node0.engine).to eq Node0.app.opt(:engine)
    end

    it "layout should return default Node's layout" do
      expect(Node0.layout).to eq Node0.app.opt(:layout)
    end

    it "engine should return class defined Node's engine" do
      expect(Node1.engine).to eq 'engine-1'
      expect(Node3.engine).to eq 'engine-2'
    end

    it "layout should return class defined Node's layout" do
      expect(Node1.layout).to eq 'layout-1'
      expect(Node3.layout).to eq 'layout-2'
    end

    it 'engine should return engine inherited from Node2' do
      expect(Node2.engine).to eq 'engine-1'
    end

    it 'layout should return layout inherited from Node2' do
      expect(Node2.layout).to eq 'layout-1'
    end

    it 'r should build a well formed path' do
      expect(Node1.r(1, 'arg2', 'some')).to eq '/node1/1/arg2/some'
    end

    it 'instance level map should work' do
      r = Node0.my_call '/with_2args/1/2'
      h = YAML.load r.body[0]
      expect(h[:map]).to eq '/node0'
    end

    it 'should return err404 response when no method found' do
      expect(Node0.respond_to?('noresponse')).to be_falsey
      r = Node0.my_call '/noresponse'
      expect(r.status).to eq 404
    end

    it 'simple method should respond' do
      r = Node0.my_call '/hello'
      expect(r.status).to eq 200
      expect(r.body[0]).to eq 'world'
    end

    it 'instance level args should work' do
      r = Node0.my_call '/with_2args/1/2'
      h = YAML.load r.body[0]
      expect(h[:args][0]).to eq '1'
      expect(h[:args][1]).to eq '2'
    end

    it 'should raise error when too much arguments' do
      expect(-> { Node0.my_call '/with_2args/1/2/3' }).to raise_error ArgumentError
    end

    it 'layout proc, method level layout and engine definitions should work' do
      r = Node0.my_call '/index'
      expect(r.status).to eq 200
      h = YAML.load r.body[0]
      ly = File.join Node0.app.layout_base_path, Node0.layout
      vu = File.join Node0.app.view_base_path, Node0.r, 'index'
      expect(h[:path]).to eq ly
      expect(h[:layout]).to eq ly
      expect(h[:view]).to eq vu
    end

    it 'layout proc, method level layout and engine definitions should work' do
      r = Node1.my_call '/index'
      expect(r.status).to eq 200
      h = YAML.load r.body[0]
      ly = File.join Node1.app.layout_base_path, 'main.spec'
      vu = File.join Node1.app.view_base_path, Node1.r, 'index.spec'
      expect(h[:path]).to eq ly
      expect(h[:layout]).to eq ly
      expect(h[:view]).to eq vu
    end

    it 'before_all hook should work' do
      Node3.before = 0
      Node3.after = 0
      expect(Node3.before).to eq 0
      expect(Node3.my_call_i('/index')).to eq 1
      expect(Node3.before).to eq 1
      expect(Node3.my_call_i('/index')).to eq 1
      expect(Node3.before).to eq 2
      expect(Node3.my_call_i('/index')).to eq 1
      expect(Node3.before).to eq 3
    end

    it 'after_all hook should work' do
      Node3.before = 0
      Node3.after = 0
      expect(Node3.after).to eq 0
      expect(Node3.my_call_i('/index')).to eq 1
      expect(Node3.after).to eq 1
      expect(Node3.my_call_i('/index')).to eq 1
      expect(Node3.after).to eq 2
      expect(Node3.my_call_i('/index')).to eq 1
      expect(Node3.after).to eq 3
    end

    it 'inherited before_all hook should work' do
      Node3.before = 0
      Node3.after = 0
      expect(Node3.before).to eq 0
      expect(Node8.my_call_i('/index')).to eq 1
      expect(Node3.before).to eq 1
      expect(Node8.my_call_i('/index')).to eq 1
      expect(Node3.before).to eq 2
      expect(Node8.my_call_i('/index')).to eq 1
      expect(Node3.before).to eq 3
    end

    it 'inherited after_all hook should work' do
      Node3.before = 0
      Node3.after = 0
      expect(Node3.after).to eq 0
      expect(Node8.my_call_i('/index')).to eq 1
      expect(Node3.after).to eq 1
      expect(Node8.my_call_i('/index')).to eq 1
      expect(Node3.after).to eq 2
      expect(Node8.my_call_i('/index')).to eq 1
      expect(Node3.after).to eq 3
    end

    it 'should find view and layout and render them' do
      r = Node0.my_call '/do_render'
      expect(r.status).to eq 200
      expect(r.body[0]).to eq 'layout_start view_content layout_end'
    end

    it 'default mime-type should be text/html' do
      r = Node0.my_call '/index'
      expect(r.headers['Content-type']).to eq 'text/html'
    end

    it 'should be able to override mime-type' do
      r = Node0.my_call '/do_render'
      expect(r.headers['Content-type']).to eq 'text/view'
    end

    it 'should be able to override through rack response mime-type' do
      r = Node0.my_call '/do_content_type'
      expect(r.headers['Content-type']).to eq 'text/mine'
    end

    it 'partial should render correctly' do
      expect(Node0.partial({}, :do_partial, 1, 2)).to eq 'partial_content'
    end

    it 'method level view should work' do
      expect(Node0.partial({}, :other_view)).to eq 'partial_content'
    end

    it 'partial with hooks should be default' do
      Node3.before = 0
      Node3.after = 0
      expect(Node3.partial({}, :do_partial, 1, 2)).to eq 'partial_content'
      expect(Node3.before).to eq 1
      expect(Node3.after).to eq 1
    end

    it 'partial without hooks should work' do
      Node3.before = 0
      Node3.after = 0
      expect(Node3.partial({ no_hooks: true }, :do_partial, 1, 2)).to eq 'partial_content'
      expect(Node3.before).to eq 0
      expect(Node3.after).to eq 0
    end

    it 'static pages should be generated' do
      r = Node6.my_call '/do_static'
      expect(r.body[0]).to eq 'VAL 1'
      expect(r.headers['Content-type']).to eq 'text/static'
      r = Node6.my_call '/do_static'
      expect(r.body[0]).to eq 'VAL 1'
      expect(r.headers['Content-type']).to eq 'text/static'
      r = Node6.my_call '/do_static'
      expect(r.body[0]).to eq 'VAL 1'
      expect(r.headers['Content-type']).to eq 'text/static'
      r = Node6.my_call '/no_static'
      expect(r.body[0]).to eq 'VAL 4'
      expect(r.headers['Content-type']).to eq 'text/static'
      r = Node6.my_call '/do_static'
      expect(r.body[0]).to eq 'VAL 1'
      expect(r.headers['Content-type']).to eq 'text/static'
      Node6.static! true, 0.000001
      sleep 0.0001
      r = Node6.my_call '/do_static'
      expect(r.body[0]).to eq 'VAL 6'
      expect(r.headers['Content-type']).to eq 'text/static'
    end

    it 'redirect should work' do
      r = Node0.my_call '/do_redirect'
      expect(r.status).to eq 302
      expect(r.headers['location']).to eq Node0.r(:do_partial, 1, 2, 3)
    end

    it 'no_layout! should be inherited' do
      expect(Node5.layout).to be_nil
    end

    it 'cli_vals should be inherited and extended' do
      r = Node5.my_call '/index'
      vars = YAML.load r.body[0]
      expect(vars).to eq %w[js0 js1 js3 jsx css0 css1 css2]
      expect(vars[7]).to be_nil
    end

    it 'cli_vals should be extended at method level' do
      r = Node4.my_call '/more'
      vars = YAML.load r.body[0]
      expect(vars).to eq %w[js0 js1 js2]
      expect(vars[3]).to be_nil
    end

    it 'cli_vals should be untouched' do
      r = Node4.my_call '/index'
      vars = YAML.load r.body[0]
      expect(vars).to eq %w[js0 js1]
      expect(vars[2]).to be_nil
      r = Node5.my_call '/index'
      vars = YAML.load r.body[0]
      expect(vars).to eq %w[js0 js1 js3 jsx css0 css1 css2]
      expect(vars[7]).to be_nil
    end

    it 'ext definition and file engine should work' do
      r = Node0.my_call '/xml_file'
      expect(r.body[0]).to eq "<xml>file<\/xml>\n"
      expect(r.headers['Content-type']).to eq 'application/xml'
      r = Node0.my_call '/plain_file'
      expect(r.body[0]).to eq "plain file\n"
      expect(r.headers['Content-type']).to eq 'text/plain'
    end

    it 'no view no layout should work as well' do
      r = Node0.my_call '/no_view_no_layout'
      expect(r.body[0]).to eq 'hello world'
    end

    it 'haml engine should work' do
      Node0.app.opt! :engines_cache_enabled, false
      r = Node0.my_call '/engines/haml'
      expect(r.body[0]).to eq "<h1>Hello world</h1>\n"
      Node0.app.opt! :engines_cache_enabled, true
      r = Node0.my_call '/engines/haml'
      expect(r.body[0]).to eq "<h1>Hello world</h1>\n"
    end

    it 'sass engine should work' do
      Node0.app.opt! :engines_cache_enabled, true
      r = Node0.my_call '/engines/sass'
      expect(r.body[0]).to eq "vbar{width:80%;height:23px}vbar ul{list-style-type:none}vbar li{float:left}vbar li a{font-weight:bold}\n"
      Node0.app.opt! :engines_cache_enabled, false
      r = Node0.my_call '/engines/sass'
      expect(r.body[0]).to eq "vbar{width:80%;height:23px}vbar ul{list-style-type:none}vbar li{float:left}vbar li a{font-weight:bold}\n"
    end

    it 'view_base_path! should work' do
      r = Node7.my_call '/view_path'
      h = YAML.load r.body[0]
      expect(h[:view]).to eq File.join(Node7.app.opt(:root), 'alt', 'do_render')
    end

    it 'layout_base_path! should work' do
      r = Node7.my_call '/view_path'
      h = YAML.load r.body[0]
      expect(h[:layout]).to eq File.join(Node7.app.opt(:root), 'alt', 'layout', 'default')
    end

    it 'debug out should work' do
      stderr0 = $stderr.dup
      stderrs = StringIO.new
      $stderr = stderrs
      begin
        APP.opt! :debug, true
        Node0.my_call '/hello'
      ensure
        $stderr = stderr0
      end
      expect(stderrs.string.include?('spec/data/view/node0/hello')).to be true
    end
  end
end
