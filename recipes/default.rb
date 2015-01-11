#
# Cookbook Name:: oracle_jdk
# Recipe:: default
#
# Copyright 2014 Brian Clark
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

version = node['oracle_jdk']['version'].to_s

fail "Unsupported JDK version: #{version}" unless %w(7 8).include?(version)

url = node['oracle_jdk'][version.to_s]['url']
checksum = node['oracle_jdk'][version.to_s]['checksum']
path = node['oracle_jdk']['path']
name = node['oracle_jdk']['app_name'] || "java-1.#{version}.0-oracle"
java_home = ::Pathname.new(name).absolute? ? name : ::File.join(path, name)

oracle_jdk "jdk-#{version}" do
  url url
  checksum checksum
  path node['oracle_jdk']['path']
  app_name name
  owner node['oracle_jdk']['owner']
  group node['oracle_jdk']['group']
  mode node['oracle_jdk']['mode']
  set_alternatives node['oracle_jdk']['set_alternatives']
  priority node['oracle_jdk']['priority']
  set_default node['oracle_jdk']['set_default']
end

directory '/etc/profile.d' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  only_if { node['oracle_jdk']['set_java_home'] == true }
end

file '/etc/profile.d/jdk.sh' do
  owner 'root'
  group 'root'
  content "export JAVA_HOME=#{java_home}"
  mode '0755'
  only_if { node['oracle_jdk']['set_java_home'] == true }
end
