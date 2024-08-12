require 'spec_helper'

describe Zorglub do
  describe Zorglub::App do
    it 'map should add a mapped node' do
      expect(APP.at('/temp')).to be_nil
      APP.map '/temp', Temp
      expect(APP.at('/temp')).to be Temp
    end

    it 'delete should delete a mapped node' do
      expect(APP.at('/temp')).to be Temp
      APP.delete '/temp'
      expect(APP.at('/temp')).to be_nil
    end

    it 'at should return mapped node' do
      expect(APP.at('/node1')).to be Node1
    end

    it 'at should return nil if no Node mapped' do
      expect(APP.at('/none')).to be_nil
    end

    it 'to should return path to node' do
      expect(APP.to(Node1)).to eq '/node1'
    end

    it 'to should return nil if not an existing Node' do
      expect(APP.to(nil)).to be_nil
    end

    it 'to_hash should return a correct hash' do
      expect(APP.to_hash['/node1']).to be Node1
    end
  end
end
