# Basic virtualbox configuration
Exec { path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" }

node basenode {
  package{["build-essential", "git-core", "vim"]:
    ensure => installed
  }
}

class xfstools {
    package{['lvm2', 'xfsprogs']:
        ensure => installed
    }
}
class java {
    package {['openjdk-7-jre-headless']:
        ensure => installed 
    }
}

class cassandra {
  include xfstools
  include java

  package { "curl": }

  file {"/etc/apt/sources.list.d/cassandra.list":
    mode    => '0644',
    content => "deb http://debian.datastax.com/community stable main",
  }

  exec {"add datastax apt key":
    command     => "curl -L http://debian.datastax.com/debian/repo_key | apt-key add -",
    require     => Package["curl"],
    subscribe   => File["/etc/apt/sources.list.d/cassandra.list"],
    refreshonly => true,
  }

  exec {"apt update for datastax repo":
    command     => "apt-get update",
    subscribe   => Exec["add datastax apt key"],
    refreshonly => true,
  }

  package {"dsc20":
    ensure  => latest,
    require => [ Exec["apt update for datastax repo"],
                 Package['openjdk-7-jre-headless'],
    ],
  }

  service {"cassandra":
    ensure  => running,
    require => Package["dsc20"],
  }
}

node cassandraengine inherits basenode {
  include cassandra
  
  package {["python-pip", "python-dev", "python-nose"]:
    ensure => installed
  }

  exec {"install-requirements":
    cwd => "/vagrant",
    command => "pip install -r requirements.txt && pip install -r requirements-dev.txt",
    require => [Package["python-pip"], Package["python-dev"]]
  }
}
