# rubocop:disable Metrics/LineLength
require 'serverspec'

set :backend, :exec

describe file('/usr/lib/jvm') do
  it { should be_directory }
end

describe file('/usr/lib/jvm/java-1.7.0-oracle') do
  it { should be_symlink }
end

describe file('/etc/profile.d/jdk.sh') do
  it { should be_file }
  it { should contain 'export JAVA_HOME=/usr/lib/jvm/java-1.7.0-oracle' }
end

if %w(debian ubuntu).include? os[:family]
  describe file('/usr/lib/jvm/.java-1.7.0-oracle.jinfo') do
    it { should be_file }
  end
end

describe command('java -version') do
  its(:stdout) { should match(/java version \"1.7.0_\d{2}\"/) }
  its(:stdout) { should match(/Java\(TM\) SE Runtime Environment/) }
end

case os[:family]
when 'redhat'
  alt_cmd = 'alternatives'
  priority = '2700\d{2}'
when 'debian', 'ubuntu'
  alt_cmd = 'update-alternatives'
  priority = '17\d{2}'
end

describe command("#{alt_cmd} --display java") do
  its(:stdout) do
    should match %r{points to /usr/lib/jvm/jdk1.7.0_\d{2}/jre/bin/java}
  end
  its(:stdout) do
    should match %r{/usr/lib/jvm/jdk1.7.0_\d{2}/jre/bin/java - priority #{priority}}
  end
end
