# Class: jenkins_darwin::slave
#
#
#  ensure is not immplemented yet, since i'm assuming you want to actually run the slave by declaring it..
#
class jenkins_darwin::slave (
  $masterurl = undef,
  $ui_user = undef,
  $ui_pass = undef,
  $version = '1.9',
  $executors = '4',
  $mode = undef,
  $jenkins_user = 'jenkins',
  $jenkins_home = '/var/lib/jenkins',
  $labels = undef,
  $slave_name = undef,
  $envfile = undef,
  $log_dir = '/var/log/jenkins'
) {

  $client_jar = "swarm-client-${version}-jar-with-dependencies.jar"
  $client_url = "http://maven.jenkins-ci.org/content/repositories/releases/org/jenkins-ci/plugins/swarm-client/${version}/"

  case $::osfamily {
    'Darwin': {
      $java_package = 'jdk-7u21.dmg'
    }

    default: {
      fail( "Unsupported OS family: ${::osfamily}" )
    }
  }


  #package { $java_package:
  #  ensure => installed;
  #}


  file { [ "$jenkins_home","$log_dir" ]:
    ensure => directory,
    owner => 'jenkins',
  }

  exec { 'get_swarm_client':
    command      => "curl -O ${client_url}${client_jar}",
    path         => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
    user         => $jenkins_user,
    #refreshonly => true,
    creates      => "${jenkins_home}/${client_jar}",
    cwd          => "${jenkins_home}",
    ## needs to be fixed if you create another version..
  }

  if $ui_user {
    $ui_user_flag = "-username ${ui_user}"
  }
  else {$ui_user_flag = ''}

  if $ui_pass {
    $ui_pass_flag = "-password ${ui_pass}"
  } else {
    $ui_pass_flag = ''
  }

  if $masterurl {
    $masterurl_flag = "-master ${masterurl}"
  } else {
    $masterurl_flag = ''
  }

  if $slave_name  {
    $slavename_flag = "-name $slavename"
  } else {
    $slavename_flag = ''
  }

  if $labels {
    $labels_flag = "-labels $labels"
  } else {
    $labels_flag = ''
  }
  if $executors {
    $executors_flag = "-executors $executors"
  } else {
    $executors_flag = ''
  }
  if $mode {
    $mode_flag = "-mode $mode"
  } else {
    $mode_flag = ''
  }


  file { '/Library/LaunchDaemons/org.jenkins-ci.slave.jnlp.plist':
    ensure => 'file',
    mode => 644,
    owner => 'root',
    group => 'wheel',
    content => template("jenkins_darwin/org.jenkins-ci.slave.jnlp.plist.erb"),
    notify  => Service['jenkins-slave']
  }

  file { "$jenkins_home/start-slave.sh":
    ensure => 'file',
    mode => 755,
    owner => 'root',
    group => 'wheel',
    content => template("jenkins_darwin/start-slave.sh.erb"),
    notify  => Service['jenkins-slave']
  }

  service { 'jenkins-slave':
    ensure     => true,
    enable     => true,
    name => 'org.jenkins-ci.slave.jnlp'
  }

  Package[ $java_package ]
  -> Exec['get_swarm_client']
  -> Service['jenkins-slave']

}
