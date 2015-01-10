#
# Cookbook Name:: oracle_jdk
# Provider:: default
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

use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

def load_current_resource
  @tarball_name = ::File.basename(new_resource.url)
  match =
    /jdk-(\d)u(\d+)-linux-(x64|i586)\.(tar.gz|gz|tgz)$/.match(@tarball_name)
  fail "Unrecognized or unsupported Oracle JDK: #{@tarball_name}" unless match
  @version, @revision, @extension = match[1], match[2], match[4]
end

def jdk_name
  "jdk1.#{@version}.0_#{@revision}"
end

def app_group
  new_resource.group || Etc.getpwnam(new_resource.owner).gid
end

def app_home
  ::File.join(new_resource.path, jdk_name)
end

def app_link
  return unless new_resource.link
  link =  if ::Pathname.new(new_resource.link).absolute?
            new_resource.link
          else
            ::File.join(new_resource.path, new_resource.link)
          end
  link == app_home ? nil : link
end

def jre_cmds
  node['oracle_jdk'][@version.to_s]['jre_cmds']
end

def jdk_cmds
  node['oracle_jdk'][@version.to_s]['jdk_cmds']
end

def alt_priority
  if platform_family?('rhel')
    # OpenJDK 6 uses 16000, OpenJDK 7 uses 170071 for 1.7.0_71
    # OpenJDK 8 (currently) uses 2-digit priority
    # Use 2V00RR (V=version, RR=revision) to win over OpenJDK 7
    priority = 200_000 + (@version.to_i * 10_000) + @revision.to_i
  else
    # Use 1VRR (V=version, RR=revision)
    # This should win over equivalent OpenJDK in Ubuntu
    priority = 1000 + (@version.to_i * 100) + @revision.to_i
  end
  new_resource.priority || priority
end

action :install do
  if new_resource.checksum.nil? || new_resource.checksum.empty?
    fail %(Attribute 'checksum' required on :install action)
  end

  archive_dir = Chef::Config[:file_cache_path]
  archive_path = ::File.join(archive_dir, @tarball_name)
  extracted_archive_path = ::File.join(archive_dir, jdk_name)

  case @extension
  when 'tar.gz', 'gz', 'tgz'
    extract_cmd = %(tar xzf "#{archive_path}" -C "#{archive_dir}" )
  else
    # TODO: Support more types??
    fail "Unable to extract #{@tarball_name}, unsupported type"
  end

  if new_resource.url =~ %r{^http://download.oracle.com.*$}
    unless node['oracle_jdk']['accept_oracle_download_terms'] == true
      msg = %(Attribute node['oracle_jdk']['accept_oracle_download_terms'] )
      msg << %(must be true to download directly from Oracle!)
      fail msg
    end
    headers = { 'Cookie' => 'oraclelicense=accept-securebackup-cookie' }
  else
    headers = {}
  end

  remote_file archive_path do
    source new_resource.url
    checksum new_resource.checksum
    headers(headers)
  end

  directory new_resource.path do
    owner new_resource.owner
    group app_group
    mode new_resource.mode
  end

  bash 'extract oracle jdk' do
    code <<-EOH
      set -e
      #{extract_cmd}
      gzip #{extracted_archive_path}/man/man1/*.1
      mv "#{extracted_archive_path}" "#{app_home}"
      chown -R #{new_resource.owner}:#{app_group} "#{app_home}"
      EOH
    not_if { ::File.directory?(app_home) }
  end

  link jdk_name do
    target_file app_link
    to app_home
    owner new_resource.owner
    group app_group
    only_if { app_link }
  end

  case node['platform_family']
  when 'rhel'
    cmd = alt_group(jre_cmds, "#{app_home}/jre/bin", alt_priority, app_home)
    cmd << alt_line("#{new_resource.path}/jre", 'jre', "#{app_home}/jre")
    guard = %(alternatives --display java | grep )
    guard << %("#{app_home}/jre/bin/java - priority #{alt_priority}")

    execute 'install java alternative' do
      command cmd.join(" \\\n")
      action :run
      not_if guard
    end

    cmd = alt_group(jdk_cmds, "#{app_home}/bin", alt_priority, app_home)
    cmd << alt_line("#{new_resource.path}/java_sdk", 'java_sdk', app_home)
    guard = %(alternatives --display javac | grep )
    guard << %("#{app_home}/bin/javac - priority #{alt_priority}")

    execute 'install javac alternative' do
      command cmd.join(" \\\n")
      action :run
      not_if guard
    end

    cmd = alt_line("#{new_resource.path}/jre-1.#{@version}.0",
                   "jre_1.#{@version}.0", "#{app_home}/jre", alt_priority)
    guard = %(alternatives --display jre_1.#{@version}.0 | grep )
    guard << %("#{app_home}/jre - priority #{alt_priority}")

    execute "install jre_1.#{@version}.0 alternative" do
      command cmd
      action :run
      not_if guard
    end

    cmd = alt_line("#{new_resource.path}/java-1.#{@version}.0",
                   "java_sdk_1.#{@version}.0", app_home, alt_priority)
    guard = %(alternatives --display java_sdk_1.#{@version}.0 | grep )
    guard << %("#{app_home} - priority #{alt_priority}")

    execute "install java_sdk_1.#{@version}.0 alternative" do
      command cmd
      action :run
      not_if guard
    end

    if new_resource.set_default
      {
        'java' => "#{app_home}/jre/bin/java",
        'javac' => "#{app_home}/bin/javac",
        "jre_1.#{@version}.0" => "#{app_home}/jre",
        "java_sdk_1.#{@version}.0" => app_home
      }.each do |name, path|
        guard = %(alternatives --display #{name} | grep )
        guard << %("link currently points to #{path}")
        execute "set #{name} alternative" do
          command %(alternatives --set #{name} "#{path}")
          action :run
          not_if guard
        end
      end
    end

  when 'debian'
    template "#{new_resource.path}/.#{jdk_name}.jinfo" do
      source 'oracle.jinfo.erb'
      owner new_resource.owner
      group app_group
      variables(
        priority: alt_priority,
        jre_cmds: jre_cmds,
        jdk_cmds: jdk_cmds,
        name: jdk_name,
        app_home: app_home)
    end

    jre_cmds.each do |java_cmd|
      cmd = alt_group(java_cmd, "#{app_home}/jre/bin", alt_priority, app_home)
      guard = %(update-alternatives --display #{java_cmd} | grep )
      guard << %("#{app_home}/jre/bin/#{java_cmd} - priority #{alt_priority}")
      execute "install #{java_cmd} alternative" do
        command cmd.join(" \\\n")
        action :run
        not_if guard
      end
    end

    jdk_cmds.each do |java_cmd|
      cmd = alt_group(java_cmd, "#{app_home}/bin", alt_priority, app_home)
      guard = %(update-alternatives --display #{java_cmd} | grep )
      guard << %("#{app_home}/bin/#{java_cmd} - priority #{alt_priority}")
      execute "install #{java_cmd} alternative" do
        command cmd.join(" \\\n")
        action :run
        not_if guard
      end
    end

    if new_resource.set_default
      jre_cmds.each do |java_cmd|
        path = ::File.join(app_home, 'jre', 'bin', java_cmd)
        guard = %(update-alternatives --display #{java_cmd} | grep )
        guard << %("link currently points to #{path}")
        execute "set #{java_cmd} alternative" do
          command %(update-alternatives --set #{java_cmd} "#{path}")
          action :run
          not_if guard
        end
      end

      jdk_cmds.each do |java_cmd|
        path = ::File.join(app_home, 'bin', java_cmd)
        guard = %(update-alternatives --display #{java_cmd} | grep )
        guard << %("link currently points to #{path}")
        execute "set #{java_cmd} alternative" do
          command %(update-alternatives --set #{java_cmd} "#{path}")
          action :run
          not_if guard
        end
      end
    end
  end
end

action :remove do

  link jdk_name do
    target_file app_link
    to app_home
    action :delete
    only_if { app_link }
  end

  directory app_home do
    recursive true
    action :delete
  end

  case node['platform_family']
  when 'rhel'
    {
      'java' => "#{app_home}/jre/bin/java",
      'javac' => "#{app_home}/bin/javac",
      "jre_1.#{@version}.0" => "#{app_home}/jre",
      "java_sdk_1.#{@version}.0" => app_home
    }.each do |name, path|
      execute "remove #{name} alternative" do
        command %(alternatives --remove #{name} "#{path}")
        action :run
        only_if %(alternatives --display #{name} | grep "#{path}")
      end
    end
  when 'debian'
    file "#{new_resource.path}/.#{jdk_name}.jinfo" do
      action :delete
    end

    jre_cmds.each do |c|
      execute "remove #{c} alternative" do
        command %(update-alternatives --remove #{c} "#{app_home}/jre/bin/#{c}")
        action :run
        only_if %(update-alternatives --display #{c} | grep "#{app_home}")
      end
    end

    jdk_cmds.each do |c|
      execute "remove #{c} alternative" do
        command %(update-alternatives --remove #{c} "#{app_home}/bin/#{c}")
        action :run
        only_if %(update-alternatives --display #{c} | grep "#{app_home}")
      end
    end
  end
end

private

def alt_line(link, name, path, priority = nil)
  alt_cmd = platform_family?('debian') ? 'update-alternatives' : 'alternatives'
  cmd = priority ? "#{alt_cmd} --install" : '--slave'
  [cmd, link, name, path, priority].compact.join(' ')
end

def alt_cmd_line(link_dir, name, real_dir, priority = nil)
  link, path = ::File.join(link_dir, name), ::File.join(real_dir, name)
  alt_line(link, name, path, priority)
end

def alt_group(java_cmds, cmd_dir, priority, jdk_home)
  java_cmds = Array(java_cmds)
  man_dir = '/usr/share/man/man1'
  cmd = []
  cmd << alt_cmd_line('/usr/bin', java_cmds[0], cmd_dir, priority)
  cmd << alt_cmd_line(man_dir, "#{java_cmds[0]}.1.gz", "#{jdk_home}/man/man1")
  java_cmds[1..-1].each do |c|
    cmd << alt_cmd_line('/usr/bin', c, cmd_dir)
    cmd << alt_cmd_line(man_dir, "#{c}.1.gz", "#{jdk_home}/man/man1")
  end
  cmd
end
