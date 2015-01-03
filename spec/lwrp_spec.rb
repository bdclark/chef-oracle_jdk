require_relative 'spec_helper'

recipe = 'oracle_jdk::default'

describe 'oracle_jdk lwrp rhel' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['oracle_jdk'],
                             file_cache_path: '/var/chef/cache',
                             platform: 'centos', version: '6.5') do |node|
      node.set['oracle_jdk']['url'] =
        'https://example.com/jdk-7u71-linux-x64.tar.gz'
      node.set['oracle_jdk']['checksum'] =
        'mychecksum'
      node.set['oracle_jdk']['path'] = '/opt/stuff'
      node.set['oracle_jdk']['owner'] = 'bob'
      node.set['oracle_jdk']['set_default'] = true
    end.converge(recipe)
  end
  let(:shellout) do
    double('shellout', run_command: nil, live_stream: nil, stdout: nil,
                       :live_stream= => nil, exitstatus: 0, error!: nil)
  end

  let(:getpwnam) { double('pwnam', uid: 'bob', gid: 99) }

  before do
    allow(Etc).to receive(:getpwnam).with('bob').and_return(getpwnam)
    java_stub = %(alternatives --display java | grep )
    java_stub << %("/opt/stuff/jdk1.7.0_71/jre/bin/java - priority 270071")
    stub_command(java_stub).and_return(false)
    javac_stub = %(alternatives --display javac | grep )
    javac_stub << %("/opt/stuff/jdk1.7.0_71/bin/javac - priority 270071")
    stub_command(javac_stub).and_return(false)
    jre_stub = %(alternatives --display jre_1.7.0 | grep )
    jre_stub << %("/opt/stuff/jdk1.7.0_71/jre - priority 270071")
    stub_command(jre_stub).and_return(false)
    sdk_stub = %(alternatives --display java_sdk_1.7.0 | grep )
    sdk_stub << %("/opt/stuff/jdk1.7.0_71 - priority 270071")
    stub_command(sdk_stub).and_return(false)
    java_link_stub = %(alternatives --display java | grep "link currently )
    java_link_stub << %(points to /opt/stuff/jdk1.7.0_71/jre/bin/java")
    stub_command(java_link_stub).and_return(false)
    javac_link_stub = %(alternatives --display javac | grep "link currently )
    javac_link_stub << %(points to /opt/stuff/jdk1.7.0_71/bin/javac")
    stub_command(javac_link_stub).and_return(false)
    jre_link_stub = %(alternatives --display jre_1.7.0 | grep "link currently )
    jre_link_stub << %(points to /opt/stuff/jdk1.7.0_71/jre")
    stub_command(jre_link_stub).and_return(false)
    sdk_link_stub = %(alternatives --display java_sdk_1.7.0 | grep "link )
    sdk_link_stub << %(currently points to /opt/stuff/jdk1.7.0_71")
    stub_command(sdk_link_stub).and_return(false)
  end

  it 'downloads jdk remote_file' do
    expect(chef_run).to create_remote_file(
      '/var/chef/cache/jdk-7u71-linux-x64.tar.gz').with(
        source: 'https://example.com/jdk-7u71-linux-x64.tar.gz',
        checksum: 'mychecksum')
  end

  it 'creates install directory' do
    expect(chef_run).to create_directory('/opt/stuff').with(
      owner: 'bob',
      group: 99,
      mode: '0755')
  end

  it 'extracts oracle jdk archive' do
    expect(chef_run).to run_bash('extract oracle jdk')
  end

  it 'installs java alternatives' do
    expect(chef_run).to run_execute('install java alternative')
  end

  it 'installs javac alternatives' do
    expect(chef_run).to run_execute('install javac alternative')
  end

  it 'installs jre_1.x.0 alternative' do
    expect(chef_run).to run_execute('install jre_1.7.0 alternative')
  end

  it 'installs java_sdk_1.x.0 alternative' do
    expect(chef_run).to run_execute('install java_sdk_1.7.0 alternative')
  end

  it 'sets java alternative' do
    expect(chef_run).to run_execute('set java alternative')
  end

  it 'sets javac alternative' do
    expect(chef_run).to run_execute('set javac alternative')
  end

  it 'sets jre_1.x.0 alternative' do
    expect(chef_run).to run_execute('set jre_1.7.0 alternative')
  end

  it 'sets java_sdk_1.x.0 alternative' do
    expect(chef_run).to run_execute('set java_sdk_1.7.0 alternative')
  end
end
