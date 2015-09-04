# rubocop:disable Metrics/LineLength
require 'serverspec'

set :backend, :exec

case os[:family]
when 'redhat'
  alt_cmd = 'alternatives'
  platform_family = 'rhel'
when 'debian', 'ubuntu'
  alt_cmd = 'update-alternatives'
  platform_family = 'debian'
end

describe file('/opt/jdks') do
  it { should be_directory }
end

describe file('/opt/jdks/oracle-jdk7') do
  it { should be_symlink }
end

describe file('/opt/jdks/oracle-jdk8') do
  it { should be_symlink }
end

if platform_family == 'debian'
  describe file('/usr/lib/jvm/.oracle-jdk7.jinfo') do
    it { should be_file }
  end

  describe file('/usr/lib/jvm/.oracle-jdk8.jinfo') do
    it { should_not be_file }
  end
end

describe command('/opt/jdks/oracle-jdk7/bin/java -version 2>&1') do
  its(:stdout) { should match(/java version \"1.7.0_\d{2}\"/) }
  its(:stdout) { should match(/Java\(TM\) SE Runtime Environment/) }
end

describe command('/opt/jdks/oracle-jdk8/bin/java -version 2>&1') do
  its(:stdout) { should match(/java version \"1.8.0_\d{2}\"/) }
  its(:stdout) { should match(/Java\(TM\) SE Runtime Environment/) }
end

describe command("#{alt_cmd} --display java 2>&1") do
  # should be in manual mode due to set_default true and low alt_priority
  # compared to openjdk package
  its(:stdout) { should match(/^java.*?manual/) }
  # jdk 7 should have specified priority 1
  its(:stdout) do
    should match %r{/opt/jdks/jdk1.7.0_\d{2}/jre/bin/java - priority 1}
  end
  # current java alternative should point to jdk 7
  its(:stdout) do
    should match %r{points to /opt/jdks/jdk1.7.0_\d{2}/jre/bin/java}
  end
  # should not have alternative for jdk 8 since set_alternatives false
  its(:stdout) do
    should_not match %r{/opt/jdks/jdk1.8.0_\d{2}/jre/bin/java}
  end
end

if platform_family == 'rhel'
  # java alternative should have jre slave
  cmd = %(#{alt_cmd} --display java 2>&1 | grep "slave jre: /opt/jdks/jdk1.7.0")
  describe command(cmd) do
    its(:stdout) { should match %r{slave jre: /opt/jdks/jdk1.7.0_\d{2}/jre} }
  end
  # javac alternative should have java_sdk slave
  cmd = %(#{alt_cmd} --display javac 2>&1 | grep "slave java_sdk: /opt/jdks/jdk1.7.0")
  describe command(cmd) do
    its(:stdout) { should match %r{slave java_sdk: /opt/jdks/jdk1.7.0_\d{2}} }
  end
end
