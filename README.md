# oracle_jdk

This cookbook installs Oracle Java JDK.

## Usage

Simply include the oracle_jdk default recipe wherever you would like the oracle
jdk installed, such as a run list (`recipe[oracle_jdk]`) or a cookbook
(`include_recipe 'oracle_jdk'`). By default, Oracle JDK 7 is installed. The
`version` attribute specifies which version to install (currently 7 and 8 are
supported).

By default, the default recipe will also set the `JAVA_HOME` environment variable
globally in `/etc/profile.d`, and will configure alternatives for the oracle
jre/jdk commands.

If you wish to install multiple jdks on the same system, or wish to have greater
control over the installation, the `oracle_jdk` LWRP is also available.

### Alternatives System

One of the goals of this cookbook is to configure the linux alternatives for the
installed Oracle JDK to be as compatible as possible with OpenJDK. The intent is
to allow OpenJDK(s) and Oracle JDK(s) to peacefully co-exist on the same system,
with the ability for one to completely override the other when desired.

To download and extract an oracle jdk without installing any alternatives,
set the `set_alternatives` attribute to `false`.

#### Alternatives Priority

If an alternatives priority is not specified, this cookbook will install a jdk
with a higher priority than its OpenJDK counterpart. This means that all
jre/jdk binary commands will normally default to the installed oracle jdk. If
you prefer to install a jdk with a specific priority level, use the
`priority` attribute.

### Downloading Directly from Oracle

This cookbook allows the most recent JDK 7 or JDK 8 to be downloaded
directly from Oracle, however Oracle has been known to change the behavior of its
download site frequently. It is recommended you store the archives on an artifact
server or s3 bucket.

To download directly from Oracle, you must set the `accept_oracle_download_terms`
attribute to `true` in your cookbook, role, or environment:
```
node.default['oracle_jdk']['accept_oracle_download_terms'] = true
```
Or, to use your own artifact server, S3 bucket, etc.:
```
node.default['oracle_jdk']['version'] = '7'
node.default['oracle_jdk']['7']['url'] = 'http://repo.example.com/artifacts/jdk-7u71-linux-x64.tar.gz'
```

## Requirements

This cookbook has been tested on the following platforms, however similar
platforms may also work:

* Centos 6.5 / 7.0
* Ubuntu 12.04 / 14.04

***NOTE: This cookbook has only been tested on 64-bit architectures!***

## Node Attributes

* `node['oracle_jdk']['version']` - Oracle jdk version to download. Default `'7'`.
* `node['oracle_jdk']['7']['url']` - Download url for jdk 7.
* `node['oracle_jdk']['7']['checksum']` - sha256 checksum for jdk 7 archive.
* `node['oracle_jdk']['8']['url']` - Download url for jdk 8.
* `node['oracle_jdk']['8']['checksum']` - sha256 checksum for jdk 8 archive.
* `node['oracle_jdk']['path']` - root install path of jdk. Defaults to
`/usr/lib/jvm`.
* `node['oracle_jdk']['app_name']` - friendly name (symlink) to jdk directory.
Defaults to `"java-1.#{version}.0-oracle"`.
* `node['oracle_jdk']['set_alternatives']` - whether to install alternatives
for jre/jdk binaries. Default: `true`.
* `node['oracle_jdk']['priority']` - alternatives priority, uses oracle_jdk LWRP
defaults unless set.
* `node['oracle_jdk']['set_default']` - if true, ensures alternatives set to
this particular jdk. Default: `false`.
* `node['oracle_jdk']['owner']` - owner of jdk directories/files.
Default: `root`.
* `node['oracle_jdk']['group']` - group owning jdk directories/files. Defaults
to primary group of `owner`.
* `node['oracle_jdk']['accept_oracle_download_terms']` - set to true if
downloading jdk direct from oracle. Default: `false` .
* `node['oracle_jdk']['set_java_home']` - whether to set global JAVA_HOME in
`/etc/profile.d`. Default: `true`.

## Recipes

### default

Installs Oracle JDK, alternatives, JAVA_HOME environment variable, etc. based
on node attributes described above.

Using default attributes, this recipe will install an oracle jdk under
`/usr/lib/jvm` and symlink it to `/usr/lib/jvm/java-1.7.0-oracle`
(`java-1.8.0-oracle` for jdk 8). It will also install alternatives for all jre/jdk
commands and set JAVA_HOME in `/etc/profile.d/jdk.sh`.

In debian-based systems it will also create `/usr/lib/jvm/.java-1.7.0.jinfo`
(`.java-1.8.0.jinfo` for jdk 8) for compatibility with the
`update-java-alternatives` command.

## Resources / Providers

### oracle_jdk

Used to install one or more oracle jdks on a system.  The default recipe in this
cookbook uses this resource to install/configure the jdk.

#### Actions
* `:install` - Default.  Download and install specified oracle jdk.
* `:remove` - Remove specified oracle jdk.

#### Attributes

* `url` - Required. Download URL of Oracle jdk tarball.
* `checksum` SHA256 checksum of downloaded jdk archive. Required with
  `:install` action.
* `path` - Installation root path. Defaults to `/usr/lib/jvm`.
* `app_name` - Optional "friendly" (symlink) name. If specified, creates
symlink `path/app_name` pointing to installed jdk. If not specified, no symlink
is created.
* `set_alternatives` - Whether to install alternatives for jre/jdk commands for
this jdk. Defaults to `true`.
* `priority` - Alternatives priority. If not specified, priority is automatically
determined and set high enough to always "win" against OpenJDK (priority number
varies by platform).
* `set_default` - If `true`, will manually set this jdk as the current
alternative, but only if not already the highest priority (current) java
alternative on the system. Defaults to `false`.
* `owner` - User who owns jdk directory. Defaults to `root`.
* `group` - Group owning jdk directory. Defaults to primary group of `owner`.
* `mode` - File mode of jdk directory. Defaults to `0755`.
* `cookbook` - cookbook name used with the `oracle.jinfo.erb` template on debian-
based systems. Defaults to `oracle_jdk`.

#### Examples

Download/install oracle jdk to `/var/lib/jvm/jdk1.7_71` as root. Installs
alternatives (and their priorities) based on platform_family.
```
oracle_jdk 'jdk' do
  url 'https://repo.example.com/jdk-7u71-linux-x64.tar.gz'
  checksum '80d5705fc37fc4eabe3cea480e0530ae0436c2c086eb8fc6f65bb21e8594baf8'
end
```

Same thing, but download directly from Oracle (** not recommended in production! **)
```
node.normal['oracle_jdk']['accept_oracle_download_terms'] = true
oracle_jdk 'jdk' do
  url 'http://download.oracle.com/otn-pub/java/jdk/7u71-b14/jdk-7u71-linux-x64.tar.gz'
  checksum '80d5705fc37fc4eabe3cea480e0530ae0436c2c086eb8fc6f65bb21e8594baf8'
end
```

Download/extract jdk, symlinks to `/opt/jdks/java-7-oracle` without
installing any alternatives:
```
oracle_jdk 'jdk' do
  url 'https://repo.example.com/jdk-7u71-linux-x64.tar.gz'
  checksum '80d5705fc37fc4eabe3cea480e0530ae0436c2c086eb8fc6f65bb21e8594baf8'
  path ''/opt/jdks'
  app_name 'java-7-oracle'
  set_alternatives false
end
```

Install jdk and alternatives with manually-specified priority:
```
oracle_jdk 'jdk' do
  url 'https://repo.example.com/jdk-7u71-linux-x64.tar.gz'
  checksum '80d5705fc37fc4eabe3cea480e0530ae0436c2c086eb8fc6f65bb21e8594baf8'
  priority 10
end
```

Same as above, but set alternatives to this jdk if not already highest priority:
```
oracle_jdk 'jdk' do
  url 'https://repo.example.com/jdk-7u71-linux-x64.tar.gz'
  checksum '80d5705fc37fc4eabe3cea480e0530ae0436c2c086eb8fc6f65bb21e8594baf8'
  priority 10
  set_default true
end
```

## License and Authors
- Author:: Brian Clark (brian@clark.zone)

```text
Copyright 2015, Brian Clark

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
