
# install OpenJDK 7 to verify if set_default attribute
# in oracle_jdk lwrp manually sets alternatives
case node['platform_family']
when 'debian'
  package 'openjdk-7-jdk'
when 'rhel'
  %w(java-1.7.0-openjdk-devel java-1.7.0-openjdk).each { |p| package p }
end

node.default['oracle_jdk']['accept_oracle_download_terms'] = true

oracle_jdk 'jdk7' do
  url node['oracle_jdk']['7']['url']
  checksum node['oracle_jdk']['7']['checksum']
  path '/opt/jdks'
  app_name 'oracle-jdk7'
  priority 1
  set_default true
end

oracle_jdk 'jdk8' do
  url node['oracle_jdk']['8']['url']
  checksum node['oracle_jdk']['8']['checksum']
  path '/opt/jdks'
  app_name 'oracle-jdk8'
  set_alternatives false
end
