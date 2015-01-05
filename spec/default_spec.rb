require_relative 'spec_helper'

describe 'oracle_jdk::default' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'centos', version: '6.5') do |node|
      node.set['oracle_jdk']['url'] =
        'https://example.com/jdk-7u71-linux-x64.tar.gz'
      node.set['oracle_jdk']['checksum'] =
        'mychecksum'
      node.set['oracle_jdk']['path'] = '/opt/stuff'
      node.set['oracle_jdk']['owner'] = 'bob'
      node.set['oracle_jdk']['set_default'] = true
      node.set['oracle_jdk']['app_name'] = 'my-jdk-name'
    end.converge(described_recipe)
  end

  it 'installs oracle_jdk' do
    expect(chef_run).to install_oracle_jdk('jdk').with(
      url: 'https://example.com/jdk-7u71-linux-x64.tar.gz',
      checksum: 'mychecksum',
      path: '/opt/stuff',
      owner: 'bob',
      set_default: true,
      app_name: 'my-jdk-name')
  end
end
