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

version = node['oracle_jdk']['version']
url = node['oracle_jdk'][version.to_s]['url']
checksum = node['oracle_jdk'][version.to_s]['checksum']

oracle_jdk 'jdk' do
  url url
  checksum checksum
  path node['oracle_jdk']['path']
  app_name node['oracle_jdk']['app_name']
  owner node['oracle_jdk']['owner']
  group node['oracle_jdk']['group']
  set_default node['oracle_jdk']['set_default']
end
