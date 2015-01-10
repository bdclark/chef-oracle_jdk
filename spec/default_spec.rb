require_relative 'spec_helper'

describe 'oracle_jdk::default' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'centos', version: '6.5') do |node|
      node.set['oracle_jdk']['7']['url'] =
        'https://example.com/jdk-7u71-linux-x64.tar.gz'
      node.set['oracle_jdk']['7']['checksum'] =
        'mychecksum7'
      node.set['oracle_jdk']['8']['url'] =
        'https://example.com/jdk-8u25-linux-x64.tar.gz'
      node.set['oracle_jdk']['8']['checksum'] =
        'mychecksum8'
      node.set['oracle_jdk']['path'] = '/opt/stuff'
      node.set['oracle_jdk']['owner'] = 'bob'
      node.set['oracle_jdk']['set_default'] = true
    end.converge(described_recipe)
  end

  context 'with version attribute of 7' do
    it 'installs oracle_jdk with url and checksum of jdk 7' do
      expect(chef_run).to install_oracle_jdk('java-1.7.0-oracle').with(
        url: 'https://example.com/jdk-7u71-linux-x64.tar.gz',
        checksum: 'mychecksum7',
        path: '/opt/stuff',
        owner: 'bob',
        set_default: true)
    end
  end

  context 'with version attribute of 8' do
    it 'installs oracle_jdk with url and checksum of jdk 8' do
      chef_run.node.set['oracle_jdk']['version'] = 8
      chef_run.converge(described_recipe)

      expect(chef_run).to install_oracle_jdk('java-1.8.0-oracle').with(
        url: 'https://example.com/jdk-8u25-linux-x64.tar.gz',
        checksum: 'mychecksum8',
        path: '/opt/stuff',
        owner: 'bob',
        set_default: true)
    end
  end
end
