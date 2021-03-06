require_relative 'spec_helper'

recipe = 'oracle_test::lwrp_test'

jre_cmds = %w(java keytool orbd pack200 policytool rmid rmiregistry
              servertool tnameserv unpack200)

jdk_cmds = %w(javac appletviewer apt extcheck idlj jar jarsigner javadoc javah
              javap javaws jcmd jconsole jdb jhat jinfo jmap jps jrunscript
              jsadebugd jstack jstat jstatd native2ascii rmic schemagen
              serialver wsgen wsimport xjc)

rhel_java_alts = {
  'java' => '/opt/jdk1.7.0_71/jre/bin/java',
  'javac' => '/opt/jdk1.7.0_71/bin/javac',
  'jre_1.7.0' => '/opt/jdk1.7.0_71/jre',
  'java_sdk_1.7.0' => '/opt/jdk1.7.0_71'
}

describe 'oracle_jdk lwrp' do
  let(:platform) { nil }
  let(:version) { nil }
  let(:action) { :install }
  let(:path) { '/opt' }
  let(:set_alternatives) { nil }
  let(:set_default) { false }
  let(:priority) { nil }
  let(:url) { 'https://example.com/jdk-7u71-linux-x64.tar.gz' }
  let(:accept_terms) { false }
  let(:app_name) { nil }

  let(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['oracle_jdk'],
                             file_cache_path: '/var/chef/cache',
                             platform: platform, version: version) do |node|
      node.set['oracle_test']['url'] = url
      node.set['oracle_test']['checksum'] =
        'mychecksum'
      node.set['oracle_jdk']['accept_oracle_download_terms'] = accept_terms
      node.set['oracle_test']['path'] = path
      node.set['oracle_test']['owner'] = 'bob'
      node.set['oracle_test']['set_alternatives'] = set_alternatives
      node.set['oracle_test']['set_default'] = set_default
      node.set['oracle_test']['action'] = action
      node.set['oracle_test']['app_name'] = app_name
      node.set['oracle_test']['priority'] = priority
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
  end

  context 'with all platforms' do
    context 'with :install action' do
      context 'when url not specified' do
        let(:url) { nil }

        it 'raises an error' do
          expect { chef_run }.to raise_error
        end
      end

      context 'with non-oracle url' do
        it 'downloads jdk remote_file without oracle cookie' do
          expect(chef_run).to create_remote_file(
            '/var/chef/cache/jdk-7u71-linux-x64.tar.gz').with(
              source: url,
              checksum: 'mychecksum',
              headers: {})
        end
      end

      context 'with direct oracle url' do
        let(:url) do
          'http://download.oracle.com/7u71-b14/jdk-7u71-linux-x64.tar.gz'
        end
        let(:accept_terms) { true }
        it 'downloads jdk remote_file with oracle cookie' do
          expect(chef_run).to create_remote_file(
            '/var/chef/cache/jdk-7u71-linux-x64.tar.gz').with(
              source: url,
              checksum: 'mychecksum',
              headers:
                { 'Cookie' => 'oraclelicense=accept-securebackup-cookie' })
        end
      end

      context 'when path not specified' do
        let(:path) { nil }
        it 'creates /usr/lib/jvm install directory' do
          expect(chef_run).to create_directory('jdk-install_path').with(
            path: '/usr/lib/jvm')
        end
      end

      context 'when path is specified' do
        it 'creates specified install directory' do
          expect(chef_run).to create_directory('jdk-install_path').with(
            path: '/opt',
            owner: 'bob',
            group: 99,
            mode: '0755')
        end
      end

      it 'extracts oracle jdk archive' do
        expect(chef_run).to run_bash('extract oracle jdk').with(
          code: %r{tar xzf "/var/chef/cache/jdk-7u71-linux-x64.tar.gz"})
      end

      context 'when app_name not specified' do
        let(:app_name) { nil }

        it 'does not create symlink' do
          expect(chef_run).not_to create_link('jdk1.7.0_71')
        end
      end

      context 'when app_name is valid' do
        let(:app_name) { 'java-7-oracle' }

        it 'creates symlink in install path' do
          expect(chef_run).to create_link('jdk1.7.0_71').with(
            target_file: '/opt/java-7-oracle',
            to: '/opt/jdk1.7.0_71',
            owner: 'bob',
            group: 99)
        end
      end

      context 'when app_name contains a slash' do
        let(:app_name) { '/var/lib/java-7-oracle' }

        it 'raises an error' do
          expect { chef_run }.to raise_error
        end
      end

      context 'when app_name same as jdk name' do
        let(:app_name) { 'jdk1.7.0_71' }

        it 'does not create symlink' do
          expect(chef_run).not_to create_link('jdk1.7.0_71')
        end
      end
    end

    context 'with :remove action' do
      let(:action) { :remove }

      it 'does not download jdk remote_file' do
        expect(chef_run).not_to create_remote_file(
          '/var/chef/cache/jdk-7u71-linux-x64.tar.gz')
      end

      it 'does not create install directory' do
        expect(chef_run).not_to create_directory('jdk-install_path')
      end

      it 'does not extract oracle jdk archive' do
        expect(chef_run).not_to run_bash('extract oracle jdk')
      end

      context 'when app_name not specified' do
        it 'does not delete symlink' do
          expect(chef_run).not_to delete_link('jdk1.7.0_71')
        end
      end

      context 'when app_name is valid' do
        let(:app_name) { 'java-7-oracle' }

        it 'deletes symlink in install path' do
          expect(chef_run).to delete_link('jdk1.7.0_71').with(
            target_file: '/opt/java-7-oracle',
            to: '/opt/jdk1.7.0_71')
        end
      end

      context 'when app_name contains a slash' do
        let(:app_name) { '/var/lib/java-7-oracle' }

        it 'raises an error' do
          expect { chef_run }.to raise_error
        end
      end

      context 'when app_name same as jdk name' do
        let(:app_name) { 'jdk1.7.0_71' }

        it 'does not delete symlink' do
          expect(chef_run).not_to delete_link('jdk1.7.0_71')
        end
      end

      it 'deletes app directory' do
        expect(chef_run).to delete_directory('/opt/jdk1.7.0_71')
      end
    end

    context 'when set_alternatives is true' do
      let(:set_alternatives) { true }

      it 'creates /usr/lib/jvm directory' do
        expect(chef_run).to create_directory('/usr/lib/jvm').with(
          owner: 'root',
          group: 'root',
          mode: '0755')
      end
    end

    context 'when set_alternatives is false' do
      let(:set_alternatives) { false }

      it 'does not create /usr/lib/jvm directory' do
        expect(chef_run).not_to create_directory('/usr/lib/jvm')
      end
    end
  end

  context 'with rhel platform' do
    let(:platform) { 'centos' }
    let(:version) { '6.5' }

    context 'with :install action' do
      let(:action) { :install }

      before do
        # stub commands asserting alternatives not set
        rhel_java_alts.each do |cmd, path|
          stub = %(alternatives --display #{cmd} | grep )
          stub << %("#{path} - priority #{priority || '270071'}")
          stub_command(stub).and_return(false)
        end
      end

      context 'when set_alternatives is false' do
        let(:set_alternatives) { false }
        let(:set_default) { true }

        rhel_java_alts.each do |cmd, _path|
          it "does not install #{cmd} alternative" do
            expect(chef_run).not_to run_execute("install #{cmd} alternative")
          end

          it "does not set #{cmd} alternative" do
            expect(chef_run).not_to run_execute("set #{cmd} alternative")
          end
        end
      end

      context 'when alternatives not installed' do
        context 'when priority not specified' do
          rhel_java_alts.each do |cmd, _path|
            it "installs #{cmd} alternative with default priority" do
              expect(chef_run).to run_execute("install #{cmd} alternative")
                .with(command: /270071/)
            end
          end
        end

        context 'when priority is specified' do
          let(:priority) { 4444 }

          rhel_java_alts.each do |cmd, _path|
            it "installs #{cmd} alternative with specified priority" do
              expect(chef_run).to run_execute("install #{cmd} alternative")
                .with(command: /4444/)
            end
          end
        end

        it 'installs java alternative and slaves' do
          expect(chef_run).to run_execute('install java alternative').with(
            command: %r{alternatives --install /usr/bin/java java })
          # bin command slaves
          jre_cmds[1..-1].each do |cmd|
            expect(chef_run).to run_execute('install java alternative').with(
              command: %r{--slave /usr/bin/#{cmd}})
          end
          # man page slaves
          jre_cmds.each do |cmd|
            expect(chef_run).to run_execute('install java alternative').with(
              command: %r{--slave /usr/share/man/man1/#{cmd}.1.gz})
          end
          # jre slave
          expect(chef_run).to run_execute('install java alternative').with(
            command: %r{--slave /usr/lib/jvm/jre jre})
        end

        it 'installs javac alternative and slaves' do
          expect(chef_run).to run_execute('install javac alternative').with(
            command: %r{alternatives --install /usr/bin/javac javac })
          # bin command slaves
          jdk_cmds[1..-1].each do |cmd|
            expect(chef_run).to run_execute('install javac alternative').with(
              command: %r{--slave /usr/bin/#{cmd}})
          end
          # man page slaves
          jdk_cmds.each do |cmd|
            expect(chef_run).to run_execute('install javac alternative').with(
              command: %r{--slave /usr/share/man/man1/#{cmd}.1.gz})
          end
          # java_sdk slave
          expect(chef_run).to run_execute('install javac alternative').with(
            command: %r{--slave /usr/lib/jvm/java java_sdk})
        end

        it 'installs jre_1.x.0 alternative' do
          expect(chef_run).to run_execute('install jre_1.7.0 alternative')
            .with(command:
              %r{alternatives --install /usr/lib/jvm/jre-1.7.0 jre_1.7.0 })
        end

        it 'installs java_sdk_1.x.0 alternative' do
          expect(chef_run).to run_execute('install java_sdk_1.7.0 alternative')
            .with(command:
              %r{alternatives --install /usr/lib/jvm/java-1.7.0 java_sdk_1.7.0})
        end
      end

      context 'when alternatives installed' do
        before do
          # stub commands asserting alternatives already set
          rhel_java_alts.each do |cmd, path|
            stub = %(alternatives --display #{cmd} | grep )
            stub << %("#{path} - priority 270071")
            stub_command(stub).and_return(true)
          end
        end

        rhel_java_alts.each do |cmd, _path|
          it "does not install #{cmd} alternative" do
            expect(chef_run).not_to run_execute("install #{cmd} alternative")
          end
        end
      end

      context 'when set_default false' do
        rhel_java_alts.each do |cmd, _path|
          it "does not set #{cmd} alternative" do
            expect(chef_run).not_to run_execute("set #{cmd} alternative")
          end
        end
      end

      context 'when set_default true' do
        let(:set_default) { true }

        context 'when alternative link does not match' do
          before do
            # stub commands asserting alternative links don't match
            rhel_java_alts.each do |cmd, path|
              link_stub = %(alternatives --display #{cmd} | grep )
              link_stub << %("link currently points to #{path}")
              stub_command(link_stub).and_return(false)
            end
          end

          rhel_java_alts.each do |cmd, path|
            it "sets #{cmd} alternative" do
              expect(chef_run).to run_execute("set #{cmd} alternative").with(
                command: %(alternatives --set #{cmd} "#{path}"))
            end
          end
        end

        context 'when alternative link matches' do
          before do
            # stub commands asserting alternative links match
            rhel_java_alts.each do |cmd, path|
              link_stub = %(alternatives --display #{cmd} | grep )
              link_stub << %("link currently points to #{path}")
              stub_command(link_stub).and_return(true)
            end
          end

          rhel_java_alts.each do |cmd, _path|
            it "does not set #{cmd} alternative" do
              expect(chef_run).not_to run_execute("set #{cmd} alternative")
            end
          end
        end
      end
    end # rhel :install action

    context 'with :remove action' do
      let(:action) { :remove }

      before do
        # stub commands asserting alternatives already set
        rhel_java_alts.each do |cmd, path|
          stub = %(alternatives --display #{cmd} | grep "#{path}")
          stub_command(stub).and_return(true)
        end
      end

      context 'when alternatives installed' do
        rhel_java_alts.each do |cmd, path|
          it "deletes #{cmd} alternative" do
            expect(chef_run).to run_execute("remove #{cmd} alternative").with(
              command: "alternatives --remove #{cmd} \"#{path}\"")
          end
        end
      end

      context 'when alternatives not installed' do
        before do
          # stub commands asserting alternatives not set
          rhel_java_alts.each do |cmd, path|
            stub = %(alternatives --display #{cmd} | grep "#{path}")
            stub_command(stub).and_return(false)
          end
        end

        rhel_java_alts.each do |cmd, _path|
          it "does not delete #{cmd} alternative" do
            expect(chef_run).not_to run_execute("remove #{cmd} alternative")
          end
        end
      end
    end # rhel :remove action
  end # rhel platform

  context 'with debian platform' do
    let(:platform) { 'ubuntu' }
    let(:version) { '12.04' }

    context 'with :install action' do
      let(:action) { :install }

      before do
        # stub commands asserting alternatives not set
        jre_cmds.each do |cmd|
          stub = %(update-alternatives --display #{cmd} | grep )
          stub << %("/opt/jdk1.7.0_71/jre/bin/#{cmd} - )
          stub << %(priority #{priority || '1771'}")
          stub_command(stub).and_return(false)
        end
        jdk_cmds.each do |cmd|
          stub = %(update-alternatives --display #{cmd} | grep )
          stub << %("/opt/jdk1.7.0_71/bin/#{cmd} - )
          stub << %(priority #{priority || '1771'}")
          stub_command(stub).and_return(false)
        end
      end

      context 'when set_alternatives is false' do
        let(:set_alternatives) { false }
        let(:set_default) { true }

        it 'does not create .jinfo template' do
          expect(chef_run).not_to create_template(
            '/usr/lib/jvm/.jdk1.7.0_71.jinfo')
        end

        it 'does not install alternatives' do
          Array(jre_cmds + jdk_cmds).each do |cmd|
            expect(chef_run).not_to run_execute("install #{cmd} alternative")
          end
        end

        it 'does not set alternatives' do
          Array(jre_cmds + jdk_cmds).each do |cmd|
            expect(chef_run).not_to run_execute("set #{cmd} alternative")
          end
        end
      end

      context 'when app_name is valid' do
        let(:app_name) { 'foo' }

        it 'creates .jinfo template from app_name' do
          expect(chef_run).to create_template('/usr/lib/jvm/.foo.jinfo')
        end
      end

      context 'when app_name is not specified' do
        let(:app_name) { nil }

        it 'creates .jinfo template from jdk name' do
          expect(chef_run).to create_template('/usr/lib/jvm/.jdk1.7.0_71.jinfo')
            .with(source: 'oracle.jinfo.erb', owner: 'bob', group: 99)
        end
      end

      context 'when alternatives not installed' do
        context 'when priority not specified' do
          it 'installs alternatives with default priority' do
            Array(jre_cmds + jdk_cmds).each do |cmd|
              expect(chef_run).to run_execute("install #{cmd} alternative")
                .with(command: /1771/)
            end
          end
        end

        context 'when priority is specified' do
          let(:priority) { 4444 }

          it 'installs alternatives with specified priority' do
            Array(jre_cmds + jdk_cmds).each do |cmd|
              expect(chef_run).to run_execute("install #{cmd} alternative")
                .with(command: /4444/)
            end
          end
        end

        it 'installs alternatives for all jre/jdk commands' do
          Array(jre_cmds + jdk_cmds).each do |cmd|
            expect(chef_run).to run_execute("install #{cmd} alternative")
              .with(command:
                %r{update-alternatives --install /usr/bin/#{cmd} #{cmd}})
            # man page slaves
            expect(chef_run).to run_execute("install #{cmd} alternative")
              .with(command:
                %r{--slave /usr/share/man/man1/#{cmd}.1.gz #{cmd}.1.gz})
          end
        end
      end

      context 'when alternatives installed' do
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
            expect(chef_run).not_to run_execute("install #{cmd} alternative")
          end
        end
      end

      context 'when set_default false' do
        it 'does not set alternatives' do
          Array(jre_cmds + jdk_cmds).each do |cmd|
            expect(chef_run).not_to run_execute("set #{cmd} alternative")
          end
        end
      end

      context 'when set_default true' do
        let(:set_default) { true }

        context 'when alternative links do not match' do
          before do
            # stub commands asserting alternative links don't match
            jre_cmds.each do |cmd|
              stub = %(update-alternatives --display #{cmd} | grep "link )
              stub << %(currently points to /opt/jdk1.7.0_71/jre/bin/#{cmd}")
              stub_command(stub).and_return(false)
            end
            jdk_cmds.each do |cmd|
              stub = %(update-alternatives --display #{cmd} | grep "link )
              stub << %(currently points to /opt/jdk1.7.0_71/bin/#{cmd}")
              stub_command(stub).and_return(false)
            end
          end

          it 'sets alternatives for all jre/jdk commands' do
            Array(jre_cmds + jdk_cmds).each do |cmd|
              expect(chef_run).to run_execute("set #{cmd} alternative").with(
                command: /update-alternatives --set #{cmd}/)
            end
          end
        end

        context 'when alternative link matches' do
          before do
            # stub commands asserting alternative links match
            jre_cmds.each do |cmd|
              stub = %(update-alternatives --display #{cmd} | grep "link )
              stub << %(currently points to /opt/jdk1.7.0_71/jre/bin/#{cmd}")
              stub_command(stub).and_return(true)
            end
            jdk_cmds.each do |cmd|
              stub = %(update-alternatives --display #{cmd} | grep "link )
              stub << %(currently points to /opt/jdk1.7.0_71/bin/#{cmd}")
              stub_command(stub).and_return(true)
            end
            chef_run.converge(recipe)
          end

          it 'does not set alternatives' do
            Array(jre_cmds + jdk_cmds).each do |cmd|
              expect(chef_run).not_to run_execute("set #{cmd} alternative")
            end
          end
        end
      end
    end # debian :install action

    context 'with :remove action' do
      let(:action) { :remove }

      before do
        # stub commands asserting alternatives already set
        Array(jre_cmds + jdk_cmds).each do |cmd|
          stub = %(update-alternatives --display #{cmd} | )
          stub << %(grep "/opt/jdk1.7.0_71")
          stub_command(stub).and_return(true)
        end
      end

      context 'when app_name is valid' do
        let(:app_name) { 'foo' }

        it 'does not create .jinfo template' do
          expect(chef_run).not_to create_template(
            '/usr/lib/jvm/.foo.jinfo')
        end

        it 'deletes .jinfo file' do
          expect(chef_run).to delete_file('/usr/lib/jvm/.foo.jinfo')
        end
      end

      context 'when app_name is not specified' do
        let(:app_name) { nil }
        it 'does not create .jinfo template from jdk name' do
          expect(chef_run).not_to create_template(
            '/usr/lib/jvm/.jdk1.7.0_71.jinfo')
        end

        it 'deletes .jinfo file from jdk name' do
          expect(chef_run).to delete_file('/usr/lib/jvm/.jdk1.7.0_71.jinfo')
        end
      end

      context 'when alternatives set' do
        it 'deletes alternatives for all jre/jdk commands' do
          jre_cmds.each do |cmd|
            path = "/opt/jdk1.7.0_71/jre/bin/#{cmd}"
            expect(chef_run).to run_execute("remove #{cmd} alternative").with(
              command: "update-alternatives --remove #{cmd} \"#{path}\"")
          end
          jdk_cmds.each do |cmd|
            path = "/opt/jdk1.7.0_71/bin/#{cmd}"
            expect(chef_run).to run_execute("remove #{cmd} alternative").with(
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
        end

        it 'does not delete alternatives' do
          Array(jre_cmds + jdk_cmds).each do |cmd|
            expect(chef_run).not_to run_execute("remove #{cmd} alternative")
          end
        end
      end
    end # debian :remove action
  end # debian platform
end
