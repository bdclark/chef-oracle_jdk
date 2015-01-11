# rubocop:disable Metrics/LineLength
require 'serverspec'

set :backend, :exec

describe file('/opt/jdks') do
  it { should be_directory }
end

describe file('/opt/jdks/oracle-jdk7') do
  it { should be_symlink }
end

describe file('/opt/jdks/oracle-jdk8') do
  it { should be_symlink }
end

if %w(debian ubuntu).include? os[:family]
  describe file('/usr/lib/jvm/.oracle-jdk7.jinfo') do
    it { should be_file }
  end

  describe file('/usr/lib/jvm/.oracle-jdk8.jinfo') do
    it { should_not be_file }
  end
end

describe command('/opt/jdks/oracle-jdk7/bin/java -version') do
  its(:stdout) { should match(/java version \"1.7.0_\d{2}\"/) }
  its(:stdout) { should match(/Java\(TM\) SE Runtime Environment/) }
end

describe command('/opt/jdks/oracle-jdk8/bin/java -version') do
  its(:stdout) { should match(/java version \"1.8.0_\d{2}\"/) }
  its(:stdout) { should match(/Java\(TM\) SE Runtime Environment/) }
end

case os[:family]
when 'redhat'
  alt_cmd = 'alternatives'
when 'debian', 'ubuntu'
  alt_cmd = 'update-alternatives'
end

describe command("#{alt_cmd} --display java") do
  its(:stdout) { should match(/java - manual mode/) }

  its(:stdout) do
    should match %r{/opt/jdks/jdk1.7.0_\d{2}/jre/bin/java - priority 1}
  end

  its(:stdout) do
    should match %r{points to /opt/jdks/jdk1.7.0_\d{2}/jre/bin/java}
  end

  its(:stdout) do
    should_not match %r{/opt/jdks/jdk1.8.0_\d{2}/jre/bin/java - priority 1}
  end
end
