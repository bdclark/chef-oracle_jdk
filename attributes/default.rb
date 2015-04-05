# rubocop:disable Metrics/LineLength

# determines which url/checksum attributes to use to download oracle jdk
default['oracle_jdk']['version'] = '7'
# download urls and sha256 checksums for current oracle jdk tarballs
default['oracle_jdk']['7']['url'] = 'http://download.oracle.com/otn-pub/java/jdk/7u75-b13/jdk-7u75-linux-x64.tar.gz'
default['oracle_jdk']['7']['checksum'] = '460959219b534dc23e34d77abc306e180b364069b9fc2b2265d964fa2c281610'
default['oracle_jdk']['8']['url'] = 'http://download.oracle.com/otn-pub/java/jdk/8u40-b26/jdk-8u40-linux-x64.tar.gz'
default['oracle_jdk']['8']['checksum'] = 'da1ad819ce7b7ec528264f831d88afaa5db34b7955e45422a7e380b1ead6b04d'

# root install path of jdk
default['oracle_jdk']['path'] = '/usr/lib/jvm'
# symlink to jdk, defaults to "java-1.#{version}.0-oracle"
default['oracle_jdk']['app_name'] = nil
# whether to install alternatives for jdk binaries
default['oracle_jdk']['set_alternatives'] = true
# alternatives priority, uses calculated sane defaults unless set
default['oracle_jdk']['priority'] = nil
# if true, ensures alternatives set to this jdk
default['oracle_jdk']['set_default'] = false
# owner of jdk directories/files
default['oracle_jdk']['owner'] = 'root'
# group owning jdk directories/files, defaults to primary group of 'owner' unless set
default['oracle_jdk']['group'] = nil
# set to true if downloading direct from oracle
default['oracle_jdk']['accept_oracle_download_terms'] = false
# whether to set JAVA_HOME in /etc/profile.d
default['oracle_jdk']['set_java_home'] = true

# remaining attributes should be left alone
default['oracle_jdk']['7']['jre_cmds'] =
  %w(java keytool orbd pack200 policytool rmid rmiregistry
     servertool tnameserv unpack200)

default['oracle_jdk']['7']['jdk_cmds'] =
  %w(javac appletviewer apt extcheck idlj jar jarsigner javadoc javah
     javap javaws jcmd jconsole jdb jhat jinfo jmap jps jrunscript
     jsadebugd jstack jstat jstatd native2ascii rmic schemagen
     serialver wsgen wsimport xjc)

default['oracle_jdk']['8']['jre_cmds'] =
  %w(java jjs keytool orbd pack200 policytool rmid rmiregistry
     servertool tnameserv unpack200)

default['oracle_jdk']['8']['jdk_cmds'] =
  %w(javac appletviewer apt extcheck idlj jar jarsigner javadoc javah javap
     javapackager javaws jcmd jconsole jdb jdeps jhat jinfo jmap jps
     jrunscript jsadebugd jstack jstat jstatd native2ascii rmic schemagen
     serialver wsgen wsimport xjc)
