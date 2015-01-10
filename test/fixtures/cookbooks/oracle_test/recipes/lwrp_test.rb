node.default['oracle_test']['url'] = nil
node.default['oracle_test']['checksum'] = nil
node.default['oracle_test']['path'] = nil
node.default['oracle_test']['link'] = nil
node.default['oracle_test']['owner'] = nil
node.default['oracle_test']['group'] = nil
node.default['oracle_test']['set_default'] = nil
node.default['oracle_test']['priority'] = nil
node.default['oracle_test']['set_alternatives'] = nil

oracle_jdk 'jdk' do
  url node['oracle_test']['url']
  checksum node['oracle_test']['checksum']
  path node['oracle_test']['path']
  link node['oracle_test']['link']
  owner node['oracle_test']['owner']
  group node['oracle_test']['group']
  set_alternatives node['oracle_test']['set_alternatives']
  priority node['oracle_test']['priority']
  set_default node['oracle_test']['set_default']
  action node['oracle_test']['action'] || :install
end
