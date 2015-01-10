require_relative 'spec_helper'

recipe = 'oracle_test::lwrp_test'

jre_cmds = %w(java keytool orbd pack200 policytool rmid rmiregistry
              servertool tnameserv unpack200)

jdk_cmds = %w(javac appletviewer apt extcheck idlj jar jarsigner javadoc javah
              javap javaws jcmd jconsole jdb jhat jinfo jmap jps jrunscript
              jsadebugd jstack jstat jstatd native2ascii rmic schemagen
              serialver wsgen wsimport xjc)

describe 'oracle_jdk lwrp debian' do
  let(:ubuntu_run) do
    ChefSpec::SoloRunner.new(step_into: ['oracle_jdk'],
                             file_cache_path: '/var/chef/cache',
                             platform: 'ubuntu', version: '12.04') do |node|
      node.set['oracle_test']['url'] =
        'https://example.com/jdk-7u71-linux-x64.tar.gz'
      node.set['oracle_test']['checksum'] =
        'mychecksum'
      node.set['oracle_test']['path'] = '/opt'
      node.set['oracle_test']['owner'] = 'bob'
      node.set['oracle_test']['set_default'] = false
      node.set['oracle_test']['action'] = :install
      node.set['oracle_test']['7']['jre_cmds'] = jre_cmds
      node.set['oracle_test']['7']['jdk_cmds'] = jdk_cmds
    end.converge(recipe)
  end

  let(:shellout) do
    double('shellout', run_command: nil, live_stream: nil, stdout: nil,
                       :live_stream= => nil, exitstatus: 0, error!: nil)
  end

  let(:getpwnam) { double('pwnam', uid: 'bob', gid: 99) }

  before do
    allow(Etc).to receive(:getpwnam).with('bob').and_return(getpwnam)
    # stub commands asserting alternatives not set
    jre_cmds.each do |cmd|
      stub = %(update-alternatives --display #{cmd} | grep )
      stub << %("/opt/jdk1.7.0_71/jre/bin/#{cmd} - priority 1771")
      stub_command(stub).and_return(false)
    end
    jdk_cmds.each do |cmd|
      stub = %(update-alternatives --display #{cmd} | grep )
      stub << %("/opt/jdk1.7.0_71/bin/#{cmd} - priority 1771")
      stub_command(stub).and_return(false)
    end
  end

  context 'with :install action' do
    context 'with non-oracle url' do
      it 'downloads jdk remote_file without oracle cookie' do
        expect(ubuntu_run).to create_remote_file(
          '/var/chef/cache/jdk-7u71-linux-x64.tar.gz').with(
            source: 'https://example.com/jdk-7u71-linux-x64.tar.gz',
            checksum: 'mychecksum',
            headers: {})
      end
    end

    context 'with direct oracle url' do
      it 'downloads jdk remote_file with oracle cookie' do
        url = 'http://download.oracle.com/otn-pub/java/jdk/7u71-b14/'
        url << 'jdk-7u71-linux-x64.tar.gz'
        ubuntu_run.node.set['oracle_test']['url'] = url
        ubuntu_run.node.set['oracle_jdk']['accept_oracle_download_terms'] = true
        ubuntu_run.converge(recipe)
        expect(ubuntu_run).to create_remote_file(
          '/var/chef/cache/jdk-7u71-linux-x64.tar.gz').with(
            source: url,
            checksum: 'mychecksum',
            headers: { 'Cookie' => 'oraclelicense=accept-securebackup-cookie' })
      end
    end

    it 'creates parent directory' do
      expect(ubuntu_run).to create_directory('/opt').with(
        owner: 'bob',
        group: 99,
        mode: '0755')
    end

    it 'extracts oracle jdk archive' do
      expect(ubuntu_run).to run_bash('extract oracle jdk').with(
        code: %r{tar xzf "/var/chef/cache/jdk-7u71-linux-x64.tar.gz"})
    end

    it 'creates .jinfo template' do
      expect(ubuntu_run).to create_template('/opt/.jdk1.7.0_71.jinfo').with(
        source: 'oracle.jinfo.erb',
        owner: 'bob',
        group: 99)
    end

    context 'when alternatives not installed' do
      it 'installs alternatives for all jre/jdk commands' do
        Array(jre_cmds + jdk_cmds).each do |cmd|
          expect(ubuntu_run).to run_execute("install #{cmd} alternative").with(
            command: %r{update-alternatives --install /usr/bin/#{cmd} #{cmd}})
          # man page slaves
          expect(ubuntu_run).to run_execute("install #{cmd} alternative").with(
            command: %r{--slave /usr/share/man/man1/#{cmd}.1.gz #{cmd}.1.gz})
        end
      end
    end

    context 'when alternatives set' do
      before do
        # stub commands asserting alternatives already set
        jre_cmds.each do |cmd|
          stub = %(update-alternatives --display #{cmd} | grep )
          stub << %("/opt/jdk1.7.0_71/jre/bin/#{cmd} - priority 1771")
          stub_command(stub).and_return(true)
        end
        jdk_cmds.each do |cmd|
          stub = %(update-alternatives --display #{cmd} | grep )
          stub << %("/opt/jdk1.7.0_71/bin/#{cmd} - priority 1771")
          stub_command(stub).and_return(true)
        end
      end

      it 'does not install alternatives' do
        Array(jre_cmds + jdk_cmds).each do |cmd|
          expect(ubuntu_run).not_to run_execute("install #{cmd} alternative")
        end
      end
    end

    context 'when set_default false' do
      it 'does not set alternatives' do
        Array(jre_cmds + jdk_cmds).each do |cmd|
          expect(ubuntu_run).not_to run_execute("set #{cmd} alternative")
        end
      end
    end

    context 'when set_default true' do
      before do
        ubuntu_run.node.set['oracle_test']['set_default'] = true
      end

      context 'when alternative links do not match' do
        before do
          # stub commands asserting alternative links don't match
          jre_cmds.each do |cmd|
            link_stub = %(update-alternatives --display #{cmd} | grep "link )
            link_stub << %(currently points to /opt/jdk1.7.0_71/jre/bin/#{cmd}")
            stub_command(link_stub).and_return(false)
          end
          jdk_cmds.each do |cmd|
            link_stub = %(update-alternatives --display #{cmd} | grep "link )
            link_stub << %(currently points to /opt/jdk1.7.0_71/bin/#{cmd}")
            stub_command(link_stub).and_return(false)
          end
          ubuntu_run.converge(recipe)
        end

        it 'sets alternatives for all jre/jdk commands' do
          Array(jre_cmds + jdk_cmds).each do |cmd|
            expect(ubuntu_run).to run_execute("set #{cmd} alternative").with(
              command: /update-alternatives --set #{cmd}/)
          end
        end
      end

      context 'when alternative link matches' do
        before do
          # stub commands asserting alternative links match
          jre_cmds.each do |cmd|
            link_stub = %(update-alternatives --display #{cmd} | grep "link )
            link_stub << %(currently points to /opt/jdk1.7.0_71/jre/bin/#{cmd}")
            stub_command(link_stub).and_return(true)
          end
          jdk_cmds.each do |cmd|
            link_stub = %(update-alternatives --display #{cmd} | grep "link )
            link_stub << %(currently points to /opt/jdk1.7.0_71/bin/#{cmd}")
            stub_command(link_stub).and_return(true)
          end
          ubuntu_run.converge(recipe)
        end

        it 'does not set alternatives' do
          Array(jre_cmds + jdk_cmds).each do |cmd|
            expect(ubuntu_run).not_to run_execute("set #{cmd} alternative")
          end
        end
      end
    end
  end

  context 'with :remove action' do
    before do
      # stub commands asserting alternatives already set
      Array(jre_cmds + jdk_cmds).each do |cmd|
        stub = %(update-alternatives --display #{cmd} | grep "/opt/jdk1.7.0_71")
        stub_command(stub).and_return(true)
      end
      ubuntu_run.node.set['oracle_test']['action'] = :remove
      ubuntu_run.converge(recipe)
    end

    it 'does not download jdk remote_file' do
      expect(ubuntu_run).not_to create_remote_file(
        '/var/chef/cache/jdk-7u71-linux-x64.tar.gz')
    end

    it 'does not create parent directory' do
      expect(ubuntu_run).not_to create_directory('/opt')
    end

    it 'does not extract oracle jdk archive' do
      expect(ubuntu_run).not_to run_bash('extract oracle jdk')
    end

    it 'does not create .jinfo template' do
      expect(ubuntu_run).not_to create_template(
        '/opt/.jdk1.7.0_71.jinfo')
    end

    it 'deletes .jinfo file' do
      expect(ubuntu_run).to delete_file('/opt/.jdk1.7.0_71.jinfo')
    end

    it 'deletes app directory' do
      expect(ubuntu_run).to delete_directory('/opt/jdk1.7.0_71')
    end

    context 'when alternatives set' do
      it 'deletes alternatives for all jre/jdk commands' do
        jre_cmds.each do |cmd|
          path = "/opt/jdk1.7.0_71/jre/bin/#{cmd}"
          expect(ubuntu_run).to run_execute("remove #{cmd} alternative").with(
            command: "update-alternatives --remove #{cmd} \"#{path}\"")
        end
        jdk_cmds.each do |cmd|
          path = "/opt/jdk1.7.0_71/bin/#{cmd}"
          expect(ubuntu_run).to run_execute("remove #{cmd} alternative").with(
            command: "update-alternatives --remove #{cmd} \"#{path}\"")
        end
      end
    end

    context 'when alternatives not set' do
      before do
        # stub commands asserting alternatives not set
        Array(jre_cmds + jdk_cmds).each do |cmd|
          stub = %(update-alternatives --display #{cmd} | )
          stub << %(grep "/opt/jdk1.7.0_71")
          stub_command(stub).and_return(false)
        end
        ubuntu_run.converge(recipe)
      end

      it 'does not delete alternatives' do
        Array(jre_cmds + jdk_cmds).each do |cmd|
          expect(ubuntu_run).not_to run_execute("remove #{cmd} alternative")
        end
      end
    end
  end
end
