require_relative 'spec_helper'

describe 'oracle_jdk::default' do
  let(:version) { nil }
  let(:path) { nil }
  let(:app_name) { nil }
  let(:owner) { nil }
  let(:group) { nil }
  let(:set_alternatives) { nil }
  let(:priority) { nil }
  let(:set_default) { nil }
  let(:set_java_home) { nil }

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
      node.set['oracle_jdk']['version'] = version
      node.set['oracle_jdk']['path'] = path
      node.set['oracle_jdk']['app_name'] = app_name
      node.set['oracle_jdk']['owner'] = owner
      node.set['oracle_jdk']['group'] = group
      node.set['oracle_jdk']['set_default'] = set_default
      node.set['oracle_jdk']['set_alternatives'] = set_alternatives
      node.set['oracle_jdk']['priority'] = priority
      node.set['oracle_jdk']['set_java_home'] = set_java_home
    end.converge(described_recipe)
  end

  context 'with default attributes' do
    it 'installs jdk 7 to /usr/lib/jvm and symlinks java-1.7.0-oracle' do
      expect(chef_run).to install_oracle_jdk('jdk-7').with(
        path: '/usr/lib/jvm',
        app_name: 'java-1.7.0-oracle',
        owner: 'root',
        set_alternatives: true,
        set_default: false,
        priority: nil)
    end

    it 'creates directory /etc/profile.d' do
      expect(chef_run).to create_directory('/etc/profile.d')
    end

    it 'creates file /etc/profile.d/jdk.sh with correct JAVA_HOME' do
      expect(chef_run).to create_file('/etc/profile.d/jdk.sh').with(
        content: 'export JAVA_HOME=/usr/lib/jvm/java-1.7.0-oracle')
    end
  end

  context 'when version is 7' do
    let(:version) { '7' }
    it 'installs jdk 7 with url and checksum of jdk 7' do
      expect(chef_run).to install_oracle_jdk('jdk-7').with(
        url: 'https://example.com/jdk-7u71-linux-x64.tar.gz',
        checksum: 'mychecksum7')
    end
  end

  context 'when version is 8' do
    let(:version) { '8' }
    it 'installs jdk 8 with url and checksum of jdk 8' do
      expect(chef_run).to install_oracle_jdk('jdk-8').with(
        url: 'https://example.com/jdk-8u25-linux-x64.tar.gz',
        checksum: 'mychecksum8')
    end
  end

  context 'when unsupported version specified' do
    let(:version) { '9' }

    it 'raises an error' do
      expect { chef_run }.to raise_error
    end
  end

  context 'with manually specified attributes' do
    let(:version) { '7' }
    let(:path) { '/opt/stuff' }
    let(:app_name) { 'oracle-jdk' }
    let(:owner) { 'bob' }
    let(:group) { 'people' }
    let(:set_alternatives) { false }
    let(:priority) { 4444 }
    let(:set_default) { true }
    it 'installs oracle_jdk with specifed attributes' do
      expect(chef_run).to install_oracle_jdk('jdk-7').with(
        url: 'https://example.com/jdk-7u71-linux-x64.tar.gz',
        checksum: 'mychecksum7',
        path: '/opt/stuff',
        owner: 'bob',
        group: 'people',
        app_name: 'oracle-jdk',
        set_alternatives: false,
        priority: 4444,
        set_default: true)
    end
  end

  context 'when set_java_home is true' do
    let(:set_java_home) { true }

    it 'creates directory /etc/profile.d' do
      expect(chef_run).to create_directory('/etc/profile.d')
    end

    context 'when app_name is specified' do
      let(:path) { '/opt/stuff' }
      let(:app_name) { 'javathing' }

      it 'creates file /etc/profile.d/jdk.sh with correct JAVA_HOME' do
        expect(chef_run).to create_file('/etc/profile.d/jdk.sh').with(
          content: 'export JAVA_HOME=/opt/stuff/javathing',
          owner: 'root',
          group: 'root',
          mode: '0755')
      end
    end

    context 'when app_name is unspecified' do
      let(:path) { '/opt/stuff' }
      let(:app_name) { nil }

      it 'creates file /etc/profile.d/jdk.sh with correct JAVA_HOME' do
        expect(chef_run).to create_file('/etc/profile.d/jdk.sh').with(
          content: 'export JAVA_HOME=/opt/stuff/java-1.7.0-oracle',
          owner: 'root',
          group: 'root',
          mode: '0755')
      end
    end
  end

  context 'when set_java_home is false' do
    let(:set_java_home) { false }

    it 'does not create directory /etc/profile.d' do
      expect(chef_run).not_to create_directory('/etc/profile.d')
    end

    it 'does not create file /etc/profile.d/jdk.sh' do
      expect(chef_run).not_to create_file('/etc/profile.d/jdk.sh')
    end
  end
end
