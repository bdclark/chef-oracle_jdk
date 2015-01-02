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

oracle_jdk 'jdk' do
  url node['oracle_jdk']['url']
  checksum node['oracle_jdk']['checksum']
  path node['oracle_jdk']['path']
  owner node['oracle_jdk']['owner']
  group node['oracle_jdk']['group']
end
