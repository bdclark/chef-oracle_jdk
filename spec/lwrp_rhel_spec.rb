require_relative 'spec_helper'

recipe = 'oracle_test::lwrp_test'

jre_cmds = %w(java keytool orbd pack200 policytool rmid rmiregistry
              servertool tnameserv unpack200)

jdk_cmds = %w(javac appletviewer apt extcheck idlj jar jarsigner javadoc javah
              javap javaws jcmd jconsole jdb jhat jinfo jmap jps jrunscript
              jsadebugd jstack jstat jstatd native2ascii rmic schemagen
              serialver wsgen wsimport xjc)

java_alts = {
  'java' => '/opt/jdk1.7.0_71/jre/bin/java',
  'javac' => '/opt/jdk1.7.0_71/bin/javac',
  'jre_1.7.0' => '/opt/jdk1.7.0_71/jre',
  'java_sdk_1.7.0' => '/opt/jdk1.7.0_71'
}

describe 'oracle_jdk lwrp rhel' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['oracle_jdk'],
                             file_cache_path: '/var/chef/cache',
                             platform: 'centos', version: '6.5') do |node|
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
    # stub commands for execute guards asserting alternatives not set
    java_alts.each do |cmd, path|
      stub = %(alternatives --display #{cmd} | grep )
      stub << %("#{path} - priority 270071")
      stub_command(stub).and_return(false)
    end
  end

  context 'with :install action' do
    it 'downloads jdk remote_file' do
      expect(chef_run).to create_remote_file(
        '/var/chef/cache/jdk-7u71-linux-x64.tar.gz').with(
          source: 'https://example.com/jdk-7u71-linux-x64.tar.gz',
          checksum: 'mychecksum')
    end

    it 'creates parent directory' do
      expect(chef_run).to create_directory('/opt').with(
        owner: 'bob',
        group: 99,
        mode: '0755')
    end

    it 'extracts oracle jdk archive' do
      expect(chef_run).to run_bash('extract oracle jdk').with(
        code: %r{tar xzf "/var/chef/cache/jdk-7u71-linux-x64.tar.gz"})
    end

    context 'when alternatives not set' do
      it 'installs java alternative and slaves' do
        expect(chef_run).to run_execute('install java alternative').with(
          command: %r{alternatives --install /usr/bin/java java })
        # slave bin commands
        jre_cmds[1..-1].each do |cmd|
          expect(chef_run).to run_execute('install java alternative').with(
            command: %r{--slave /usr/bin/#{cmd}})
        end
        # slave man pages
        jre_cmds.each do |cmd|
          expect(chef_run).to run_execute('install java alternative').with(
            command: %r{--slave /usr/share/man/man1/#{cmd}.1.gz})
        end
      end

      it 'installs javac alternative and slaves' do
        expect(chef_run).to run_execute('install javac alternative').with(
          command: %r{alternatives --install /usr/bin/javac javac })
        # slave bin commands
        jdk_cmds[1..-1].each do |cmd|
          expect(chef_run).to run_execute('install javac alternative').with(
            command: %r{--slave /usr/bin/#{cmd}})
        end
        # slave man pages
        jdk_cmds.each do |cmd|
          expect(chef_run).to run_execute('install javac alternative').with(
            command: %r{--slave /usr/share/man/man1/#{cmd}.1.gz})
        end
      end

      it 'installs jre_1.x.0 alternative' do
        expect(chef_run).to run_execute('install jre_1.7.0 alternative').with(
          command: %r{alternatives --install /opt/jre-1.7.0 jre_1.7.0 })
      end

      it 'installs java_sdk_1.x.0 alternative' do
        expect(chef_run).to run_execute('install java_sdk_1.7.0 alternative')
          .with(
            command: %r{alternatives --install /opt/java-1.7.0 java_sdk_1.7.0 })
      end
    end

    context 'when alternatives set' do
      before do
        # stub commands asserting alternatives already set
        java_alts.each do |cmd, path|
          stub = %(alternatives --display #{cmd} | grep )
          stub << %("#{path} - priority 270071")
          stub_command(stub).and_return(true)
        end
      end

      it 'does not install java alternative' do
        expect(chef_run).not_to run_execute('install java alternative')
      end

      it 'does not install javac alternative' do
        expect(chef_run).not_to run_execute('install javac alternative')
      end

      it 'does not install jre_1.x.0 alternative' do
        expect(chef_run).not_to run_execute('install jre_1.7.0 alternative')
      end

      it 'does not install java_sdk_1.x.0 alternative' do
        expect(chef_run).not_to run_execute(
          'install java_sdk_1.7.0 alternative')
      end
    end

    context 'when set_default false' do
      java_alts.each do |cmd, _path|
        it "does not set #{cmd} alternative" do
          expect(chef_run).not_to run_execute("set #{cmd} alternative")
        end
      end
    end

    context 'when set_default true' do
      before do
        chef_run.node.set['oracle_test']['set_default'] = true
      end

      context 'when alternative link does not match' do
        before do
          # stub commands asserting alternative links don't match
          java_alts.each do |cmd, path|
            link_stub = %(alternatives --display #{cmd} | grep )
            link_stub << %("link currently points to #{path}")
            stub_command(link_stub).and_return(false)
          end
          chef_run.converge(recipe)
        end

        it 'sets java alternative' do
          expect(chef_run).to run_execute('set java alternative')
            .with(command:
              %r{alternatives --set java "/opt/jdk1.7.0_71/jre/bin/java"})
        end

        it 'sets javac alternative' do
          expect(chef_run).to run_execute('set javac alternative').with(
            command: %r{alternatives --set javac "/opt/jdk1.7.0_71/bin/javac"})
        end

        it 'sets jre_1.x.0 alternative' do
          expect(chef_run).to run_execute('set jre_1.7.0 alternative').with(
            command: %r{alternatives --set jre_1.7.0 "/opt/jdk1.7.0_71/jre"})
        end

        it 'sets java_sdk_1.x.0 alternative' do
          expect(chef_run).to run_execute('set java_sdk_1.7.0 alternative')
            .with(
            command: %r{alternatives --set java_sdk_1.7.0 "/opt/jdk1.7.0_71"})
        end
      end

      context 'when alternative link matches' do
        before do
          # stub commands asserting alternative links match
          java_alts.each do |cmd, path|
            link_stub = %(alternatives --display #{cmd} | grep )
            link_stub << %("link currently points to #{path}")
            stub_command(link_stub).and_return(true)
          end
          chef_run.converge(recipe)
        end

        java_alts.each do |cmd, _path|
          it "does not set #{cmd} alternative" do
            expect(chef_run).not_to run_execute("set #{cmd} alternative")
          end
        end
      end
    end
  end

  context 'with :remove action' do
    before do
      # stub commands asserting alternatives already set
      java_alts.each do |cmd, path|
        stub = %(alternatives --display #{cmd} | grep )
        stub << %("#{path}")
        stub_command(stub).and_return(true)
      end
      chef_run.node.set['oracle_test']['action'] = :remove
      chef_run.converge(recipe)
    end

    it 'does not download jdk remote_file' do
      expect(chef_run).not_to create_remote_file(
        '/var/chef/cache/jdk-7u71-linux-x64.tar.gz')
    end

    it 'does not create parent directory' do
      expect(chef_run).not_to create_directory('/opt')
    end

    it 'does not extract oracle jdk archive' do
      expect(chef_run).not_to run_bash('extract oracle jdk')
    end

    it 'deletes app directory' do
      expect(chef_run).to delete_directory('/opt/jdk1.7.0_71')
    end

    context 'when alternatives set' do
      java_alts.each do |cmd, path|
        it "deletes #{cmd} alternative" do
          expect(chef_run).to run_execute("remove #{cmd} alternative").with(
            command: "alternatives --remove #{cmd} \"#{path}\"")
        end
      end
    end

    context 'when alternatives not set' do
      before do
        # stub commands asserting alternatives not set
        java_alts.each do |cmd, path|
          stub = %(alternatives --display #{cmd} | grep )
          stub << %("#{path}")
          stub_command(stub).and_return(false)
        end
        chef_run.converge(recipe)
      end

      java_alts.each do |cmd, _path|
        it "does not delete #{cmd} alternative" do
          expect(chef_run).not_to run_execute("remove #{cmd} alternative")
        end
      end
    end
  end
end
