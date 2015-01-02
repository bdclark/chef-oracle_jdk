# rubocop:disable Metrics/LineLength

default['oracle_jdk']['url'] = 'http://steadyserv-packages.s3.amazonaws.com/oracle-jdk/jdk-7u71-linux-x64.tar.gz'
default['oracle_jdk']['checksum'] = '80d5705fc37fc4eabe3cea480e0530ae0436c2c086eb8fc6f65bb21e8594baf8'
default['oracle_jdk']['path'] = '/usr/lib/jvm'

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
