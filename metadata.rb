name             'oracle_jdk'
maintainer       'Brian Clark'
maintainer_email 'brian@clark.zone'
license          'apache2'
description      'Installs/Configures Oracle JDK'
long_description 'Installs/Configures Oracle JDK'
version          '0.4.0'

%w(centos amazon ubuntu).each { |os| supports os }
