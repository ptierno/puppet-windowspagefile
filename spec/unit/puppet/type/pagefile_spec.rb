require 'spec_helper'
require 'puppet'

describe Puppet::Type.type(:pagefile) do
  context "if path is not set" do
    it 'should raise Puppet::Error' do
      expect { Puppet::Type.type(:pagefile).new(:path => nil) }.to raise_error(Puppet::Error, /Title or name must be provided/)
    end
  end
end