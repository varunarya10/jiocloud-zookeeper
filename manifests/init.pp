# /etc/puppet/modules/zookeeper/manafests/init.pp
 
class zookeeper ($server_id) {

    require zookeeper::params
    
    group { "${zookeeper::params::zookeeper_group}":
        ensure => present,
        gid => "800"
    }

    user { "${zookeeper::params::zookeeper_user}":
        ensure => present,
        comment => "Zookeeper",
        password => "!!",
        #uid => "800",
        gid => "800",
        shell => "/bin/bash",
        home => "${zookeeper::params::zookeeper_user_path}",
        require => Group["${zookeeper::params::zookeeper_group}"],
    }

    exec { "set zookeeper path":
        command => "echo 'export PATH=${zookeeper::params::zookeeper_base}/zookeeper/bin:\$PATH' >> /etc/profile.d/hadoop.sh",
        alias => "set-zookeeperpath",
        user => "root",
        #before => Exec["set-zookeeperhome"],
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
        onlyif => "test 0 -eq $(grep -c '${zookeeper::params::zookeeper_base}/zookeeper/bin' /etc/profile.d/hadoop.sh)",
        require => [ User["${zookeeper::params::zookeeper_user}"], File["${zookeeper::params::zookeeper_user}-home"] ],
    }

    file { "${zookeeper::params::zookeeper_user_path}/.bashrc":        
        ensure => present,
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        alias => "${zookeeper::params::zookeeper_user}-bashrc",
        content => template("zookeeper/home/bashrc.erb"),
        require => User["${zookeeper::params::zookeeper_user}"]    
    }

    #exec { "set zookeeper path":
    #    command => "echo 'export PATH=${zookeeper::params::zookeeper_base}/zookeeper/bin:\$PATH' >> ${zookeeper::params::zookeeper_user_path}/.bashrc",
    #    alias => "set-zookeeperpath",
    #    user => "${zookeeper::params::zookeeper_user}",
    #    #before => Exec["set-zookeeperhome"],
    #    path    => ["/bin", "/usr/bin", "/usr/sbin"],
    #    onlyif => "test 0 -eq $(grep -c '${zookeeper::params::zookeeper_base}/zookeeper/bin' ${zookeeper::params::zookeeper_user_path}/.bashrc)",
    #    require => [ User["${zookeeper::params::zookeeper_user}"], File["${zookeeper::params::zookeeper_user}-home"] ],
    #}

    file { "${zookeeper::params::zookeeper_user_path}":
        ensure => "directory",
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        alias => "${zookeeper::params::zookeeper_user}-home",
        require => [ User["${zookeeper::params::zookeeper_user}"], Group["${zookeeper::params::zookeeper_group}"] ]
    }

 
    file { "${zookeeper::params::zookeeper_user_path}/.ssh/":
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        mode => "700",
        ensure => "directory",
        alias => "${zookeeper::params::zookeeper_user}-ssh-dir",
    }

    file { "${zookeeper::params::zookeeper_user_path}/.ssh/id_rsa.pub":
        ensure => present,
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        mode => "644",
        source => "puppet:///modules/zookeeper/ssh/id_rsa.pub",
        require => File["${zookeeper::params::zookeeper_user}-ssh-dir"],
    }

    file { "${zookeeper::params::zookeeper_user_path}/.ssh/id_rsa":
        ensure => present,
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        mode => "600",
        source => "puppet:///modules/zookeeper/ssh/id_rsa",
        require => File["${zookeeper::params::zookeeper_user}-ssh-dir"],
    }

    file { "${zookeeper::params::zookeeper_user_path}/.ssh/config":
        ensure => present,
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        mode => "600",
        source => "puppet:///modules/zookeeper/ssh/config",
        require => File["${zookeeper::params::zookeeper_user}-ssh-dir"],
    }

    file { "${zookeeper::params::zookeeper_user_path}/.ssh/authorized_keys":
        ensure => present,
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        mode => "644",
        source => "puppet:///modules/zookeeper/ssh/id_rsa.pub",
        require => File["${zookeeper::params::zookeeper_user}-ssh-dir"],
    }
 
 
    file {"${zookeeper::params::zookeeper_data_path}":
        ensure => "directory",
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        alias => "zookeeper-data-dir",
        require => File["${zookeeper::params::zookeeper_user}-home"]
    }
 
    file {"${zookeeper::params::zookeeper_base}":
        ensure => "directory",
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        alias => "zookeeper-base",
    }

     file {"${zookeeper::params::zookeeper_conf}":
        ensure => "directory",
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        alias => "zookeeper-conf",
        require => [File["zookeeper-base"], Exec["untar-zookeeper"]],
        before => [ File["zoo-cfg"] ]
    }
 
    exec { "download ${zookeeper::params::zookeeper_base}/zookeeper-${zookeeper::params::version}.tar.gz":
        command => "wget http://apache.stu.edu.tw/zookeeper/zookeeper-${zookeeper::params::version}/zookeeper-${zookeeper::params::version}.tar.gz",
        cwd => "${zookeeper::params::zookeeper_base}",
        alias => "download-zookeeper",
        user => "${zookeeper::params::zookeeper_user}",
        before => Exec["untar-zookeeper"],
        require => File["zookeeper-base"],
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
        creates => "${zookeeper::params::zookeeper_base}/zookeeper-${zookeeper::params::version}.tar.gz",
    }

    file { "${zookeeper::params::zookeeper_base}/zookeeper-${zookeeper::params::version}.tar.gz":
        mode => 0644,
        ensure => present,
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        alias => "zookeeper-source-tgz",
        before => Exec["untar-zookeeper"],
        require => [File["zookeeper-base"], Exec["download-zookeeper"]],
    }

    
    exec { "untar zookeeper-${zookeeper::params::version}.tar.gz":
        command => "tar xfvz zookeeper-${zookeeper::params::version}.tar.gz",
        cwd => "${zookeeper::params::zookeeper_base}",
        creates => "${zookeeper::params::zookeeper_base}/zookeeper-${zookeeper::params::version}",
        alias => "untar-zookeeper",
        onlyif => "test 0 -eq $(ls -al ${zookeeper::params::zookeeper_base}/zookeeper-${zookeeper::params::version} | grep -c bin)",
        user => "${zookeeper::params::zookeeper_user}",
        before => [ File["zookeeper-symlink"], File["zookeeper-app-dir"]],
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
    }

    file { "${zookeeper::params::zookeeper_base}/zookeeper-${zookeeper::params::version}":
        ensure => "directory",
        mode => 0644,
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        alias => "zookeeper-app-dir",
        require => Exec["untar-zookeeper"],
    }
        
    file { "${zookeeper::params::zookeeper_base}/zookeeper":
        force => true,
        ensure => "${zookeeper::params::zookeeper_base}/zookeeper-${zookeeper::params::version}",
        alias => "zookeeper-symlink",
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        require => File["zookeeper-source-tgz"],
        before => [ File["zoo-cfg"] ]
    }
    
    file { "${zookeeper::params::zookeeper_base}/zookeeper-${zookeeper::params::version}/conf/zoo.cfg":
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        mode => "644",
        alias => "zoo-cfg",
        require => File["zookeeper-app-dir"],
        content => template("zookeeper/conf/zoo.cfg.erb"),
    }

    file { "${zookeeper::params::zookeeper_data_path}/myid":
        owner => "${zookeeper::params::zookeeper_user}",
        group => "${zookeeper::params::zookeeper_group}",
        mode => "644",
        content => $server_id,
        require => File["zookeeper-data-dir"],
        alias => "zookeeper-myid",
    }
 
    if $zookeeper::params::kerberos_mode == "yes" {
 
        file { "${zookeeper::params::keytab_path}":
            ensure => "directory",
            owner => "root",
            group => "${zookeeper::params::zookeeper_group}",
            mode => "750",
            alias => "keytab-path",
        }
 
        file { "${zookeeper::params::keytab_path}/zookeeper.service.keytab":
            ensure => present,
            owner => "root",
            group => "${zookeeper::params::zookeeper_group}",
            mode => "440",
            source => "puppet:///modules/zookeeper/keytab/${fqdn}.zookeeper.service.keytab",
            require => File["keytab-path"],
        }
 
        file { "${zookeeper::params::keytab_path}/zkcli.service.keytab":
            ensure => present,
            owner => "root",
            group => "${zookeeper::params::zookeeper_group}",
            mode => "440",
            source => "puppet:///modules/zookeeper/keytab/${fqdn}.zkcli.service.keytab",
            require => File["keytab-path"],
        }
 
        file { "${zookeeper::params::zookeeper_base}/zookeeper-${zookeeper::params::version}/conf/jaas.conf":
            owner => "${zookeeper::params::zookeeper_user}",
            group => "${zookeeper::params::zookeeper_group}",
            mode => "644",
            alias => "jaas-cfg",
            require => File["zookeeper-app-dir"],
            content => template("zookeeper/conf/jaas.conf.erb"),
        }
        
        
        file { "${zookeeper::params::zookeeper_base}/zookeeper-${zookeeper::params::version}/conf/java.env":
            owner => "${zookeeper::params::zookeeper_user}",
            group => "${zookeeper::params::zookeeper_group}",
            mode => "644",
            alias => "java-env",
            require => File["zookeeper-app-dir"],
            content => template("zookeeper/conf/java.env.erb"),
        }


    }

}
