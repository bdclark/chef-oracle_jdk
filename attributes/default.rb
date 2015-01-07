# rubocop:disable Metrics/LineLength

default['oracle_jdk']['version'] = '7'

default['oracle_jdk']['7']['url'] = 'http://download.oracle.com/otn-pub/java/jdk/7u71-b14/jdk-7u71-linux-x64.tar.gz'
default['oracle_jdk']['7']['checksum'] = '80d5705fc37fc4eabe3cea480e0530ae0436c2c086eb8fc6f65bb21e8594baf8'
default['oracle_jdk']['8']['url'] = 'http://download.oracle.com/otn-pub/java/jdk/8u25-b17/jdk-8u25-linux-x64.tar.gz'
default['oracle_jdk']['8']['checksum'] = '057f660799be2307d2eefa694da9d3fce8e165807948f5bcaa04f72845d2f529'

default['oracle_jdk']['path'] = '/usr/lib/jvm'
default['oracle_jdk']['app_name'] = nil
default['oracle_jdk']['set_default'] = false

default['oracle_jdk']['accept_oracle_download_terms'] = false

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
