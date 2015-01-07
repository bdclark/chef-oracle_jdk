# oracle_jdk

This cookbook downloads and installs the Oracle Java JDK.

## Attributes

TODO: Documentation

## Recipes

### default

TODO: Documentation

## Lightweight Resources / Providers

### oracle_jdk

TODO: Documentation

#### Actions
* `:install` - Download and install oracle jdk. `url` and `checksum` attributes
are required.
* `:remove` - Remove oracle jdk. Either `url` or `app_name` attribute is
required to determine full path to jdk.

#### Atrributes

* `url` - Download URL (required with `:install` action)
* `checksum` SHA256 checksum of downloaded jdk archive (required with
  `:install` action)
* `path` - Installation prefix path; defaults to `/var/lib/jvm`
* `app_name` - Optional name of jdk directory. If not specified,
`app_name` is determined from `url` and defaults to `jdk1.V_RR`, where V is version and R is revision (e.g. `jdk1.7_71`)
* `set_alternatives` - Whether to install this jdk as an alternative;
defaults to `true`
* `priority` - Alternatives priority. If not specified, priority is set high
enough to always "win" against OpenJDK (varies by platform)
* `set_default` - If `true`, will manually set this jdk as the current alternative, but only if not already the highest priority (current) java
alternative on the system.
* `owner` - User who owns `app_name` directory; defaults to `root`
* `group` - Group owning `app_name` directory; defaults to primary group of `owner`
* `mode` - File mode of `app_name` directory; defaults to `0755`

#### Examples

Downloads and installs jdk to `/var/lib/jvm/jdk1.7_71` as root. Installs
alternatives (and their priorities) based on platform_family.
```
oracle_jdk 'jdk' do
  url 'https://repo.example.com/jdk-7u71-linux-x64.tar.gz'
  checksum '80d5705fc37fc4eabe3cea480e0530ae0436c2c086eb8fc6f65bb21e8594baf8'
end
```

Downloads/extracts jdk to /opt/jdks/java-7-oracle without installing
any alternatives:
```
oracle_jdk 'jdk' do
  url 'https://repo.example.com/jdk-7u71-linux-x64.tar.gz'
  checksum '80d5705fc37fc4eabe3cea480e0530ae0436c2c086eb8fc6f65bb21e8594baf8'
  path /opt/jdks
  app_name java-7-oracle
  set_alternatives false
end
```

Install jdk and alternatives with manually-specified alternative priority:
```
oracle_jdk 'jdk' do
  url 'https://repo.example.com/jdk-7u71-linux-x64.tar.gz'
  checksum '80d5705fc37fc4eabe3cea480e0530ae0436c2c086eb8fc6f65bb21e8594baf8'
  priority 10
end
```
