require_relative 'spec_helper'

describe 'oracle_jdk::default' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  it 'installs oracle_jdk' do
    expect(chef_run).to install_oracle_jdk('jdk')
  end
end
