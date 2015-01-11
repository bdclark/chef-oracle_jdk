# oracle_jdk

This cookbook downloads and installs the Oracle Java JDK.

## Attributes

* `node['oracle_jdk']['version']` - Oracle jdk version to download. Default `"7"`.
* `node['oracle_jdk']['7']['url']` - Download url for jdk 7.
* `node['oracle_jdk']['7']['checksum']` - sha256 checksum for jdk 7 tarball.
* `node['oracle_jdk']['8']['url']` - Download url for jdk 8.
* `node['oracle_jdk']['8']['checksum']` - sha256 checksum for jdk 8 tarball
* `node['oracle_jdk']['path']` - root install path of jdk.
Defaults to `/usr/lib/jvm`.
* `node['oracle_jdk']['app_name']` - friendly name (symlink) to jdk directory.
Defaults to `"java-1.#{version}.0-oracle"`.
* `node['oracle_jdk']['set_alternatives']` - whether to install alternatives
for jdk binaries. Default: `true`.
* `node['oracle_jdk']['priority']` - alternatives priority, uses oracle_jdk LWRP
defaults unless set.
* `node['oracle_jdk']['set_default']` - if true, ensures alternatives set to
this jdk. Default: `false`.
* `node['oracle_jdk']['owner']` - owner of jdk directories/files.
Default: `root`.
* `node['oracle_jdk']['group']` - group owning jdk directories/files. Defaults
to primary group of `owner`.
* `node['oracle_jdk']['accept_oracle_download_terms']` - set to true if
downloading jdk direct from oracle. Default: `false` .
* `node['oracle_jdk']['set_java_home']` - whether to set JAVA_HOME in
`/etc/profile.d`. Default: `true`.

## Recipes

### default

Simply include the oracle_jdk default recipe wherever you would like the Oracle
JDK installed, such as a run list (`recipe[oracle_jdk]`) or a cookbook
(`include_recipe 'oracle_jdk'`). By default, Oracle JDK 7 is installed. The
`version` attribute specifies which version to install (currently 7 and 8 are
supported).

By default, this recipe will also set the `JAVA_HOME` environment variable
globally in  `/etc/profile.d`.

This recipe will also configure alternatives for the oracle jdk in a fashion
similar to OpenJDK. Unless the `priority` attribute is set to a specific value,
the installed Oracle jdk will have a priority higher than its OpenJDK counterpart
and should "always win" over OpenJDK.

## Lightweight Resources / Providers

### oracle_jdk

TODO: Documentation

#### Actions
* `:install` - Default.  Download and install specified oracle jdk.
* `:remove` - Remove specified oracle jdk.

#### Atrributes

* `url` - Required. Download URL of Oracle jdk tarball.
* `checksum` SHA256 checksum of downloaded jdk archive. Required with
  `:install` action.
* `path` - Installation root path. Defaults to `/var/lib/jvm`.
* `app_name` - Optional "friendly" (symlink) name. If specified, creates
symlink `path/app_name` pointing to installed jdk. If not specified, no symlink
is created.
* `set_alternatives` - Whether to install this jdk as an alternative. Defaults
to `true`.
* `priority` - Alternatives priority. If not specified, priority is automatically
determined and set high enough to always "win" against OpenJDK (priority number
varies by platform).
* `set_default` - If `true`, will manually set this jdk as the current
alternative, but only if not already the highest priority (current) java
alternative on the system. Defaults to `false`.
* `owner` - User who owns jdk directory. Defaults to `root`.
* `group` - Group owning jdk directory. Defaults to primary group of `owner`.
* `mode` - File mode of jdk directory. Defaults to `0755`.

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
