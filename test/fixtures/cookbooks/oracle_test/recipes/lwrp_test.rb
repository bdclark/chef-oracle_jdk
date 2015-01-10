oracle_jdk 'jdk' do
  url node['oracle_test']['url']
  checksum node['oracle_test']['checksum']
  path node['oracle_test']['path']
  link node['oracle_test']['link']
  owner node['oracle_test']['owner']
  group node['oracle_test']['group']
  set_default node['oracle_test']['set_default']
  action node['oracle_test']['action'] || :install
end
