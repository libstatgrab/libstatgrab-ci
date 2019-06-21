$concurrent = 10

$boxes = [
  'alpine37',
  'alpine38',
  'alpine39',
  'alpine310',
  'arch',
  'centos6',
  'centos6i386',
  'centos7',
  'debian8',
  'debian9',
  'dragonflybsd5',
  'fedora28',
  'fedora29',
  'fedora30',
  'freebsd11',
  'freebsd12',
  'freebsd12i386',
  'gentoo',
  'hardenedbsd11',
  'hardenedbsd12',
  'netbsd8',
  'openbsd6',
  'opensuse42',
  'oracle7',
  'solaris11x86',
  'ubuntu1604',
  'ubuntu1604i386',
  'ubuntu1804',
]

package { [ 'virtualbox', 'virtualbox-ext-pack', 'vagrant', ]:
  ensure => latest,
}

include apt
apt::source { 'gitlab-runner':
  location => 'https://packages.gitlab.com/runner/gitlab-runner/ubuntu/',
  key      => {
    id     => '1A4C919DB987D435939638B914219A96E15E78F4',
    source => 'https://packages.gitlab.com/gpg.key',
  },
  include  => {
    src => false,
  },
}
package { 'gitlab-runner':
  ensure  => latest,
  require => [ Apt::Source['gitlab-runner'], Class['apt::update'], ],
  notify  => Service['gitlab-runner'],
}
service { 'gitlab-runner':
  ensure  => running,
  enable  => true,
  require => Package['gitlab-runner'],
}
file_line { '/etc/gitlab-runner/config.toml:concurrent':
  path    => '/etc/gitlab-runner/config.toml',
  line    => "concurrent = ${concurrent}",
  match   => '^\s*(?:#)?\s*concurrent\s*=\s*',
  require => Package['gitlab-runner'],
  notify  => Service['gitlab-runner'],
}

$boxes.each |String $box| {
  exec { "vagrant_up_${box}":
    command   => '/usr/bin/vagrant box update; /usr/bin/vagrant up',
    cwd       => "${::ci_dir}/$box",
    onlyif    => '/usr/bin/vagrant status | grep "not created"',
    logoutput => true,
    timeout   => 0,
    require   => Package['vagrant'],
  }
  exec { "register_runner_${box}":
    command   => "/usr/bin/gitlab-runner register --non-interactive --registration-token='${::gitlab_runner_registration_token}' --name='libstatgrab-ci-${box}' --url='https://gitlab.com/' --executor=virtualbox --virtualbox-base-name='${box}' --virtualbox-disable-snapshots --ssh-user=vagrant --ssh-password=vagrant --tag-list='libstatgrab-ci-${box}'",
    unless    => "/bin/grep libstatgrab-ci-${box} /etc/gitlab-runner/config.toml",
    logoutput => true,
    require   => Package['gitlab-runner'],
    notify    => Service['gitlab-runner'],
  }
}

# This will need copying to remote hosts manually
exec { 'create_ssh_key':
  command => "/usr/bin/ssh-keygen -C lsgci -f ${::ci_dir}/lsgci",
  cwd     => $::ci_dir,
  creates => "${::ci_dir}/lsgci",
}

exec { 'register_runner_solaris9sparc':
  command   => "/usr/bin/gitlab-runner register --non-interactive --registration-token='${::gitlab_runner_registration_token}' --name='libstatgrab-ci-solaris9sparc' --url='https://gitlab.com/' --executor=ssh --ssh-host=vulture --ssh-port=722 --ssh-user=lsgci --ssh-identity-file='${::ci_dir}/lsgci' --tag-list='libstatgrab-ci-solaris9sparc'",
  unless    => "/bin/grep libstatgrab-ci-solaris9sparc /etc/gitlab-runner/config.toml",
  logoutput => true,
  require   => [ Package['gitlab-runner'], Exec['create_ssh_key'], ],
  notify    => Service['gitlab-runner'],
}
exec { 'register_runner_solaris10sparc':
  command   => "/usr/bin/gitlab-runner register --non-interactive --registration-token='${::gitlab_runner_registration_token}' --name='libstatgrab-ci-solaris10sparc' --url='https://gitlab.com/' --executor=ssh --ssh-host=hawk --ssh-port=22 --ssh-user=lsgci --ssh-identity-file='${::ci_dir}/lsgci' --tag-list='libstatgrab-ci-solaris10sparc'",
  unless    => "/bin/grep libstatgrab-ci-solaris10sparc /etc/gitlab-runner/config.toml",
  logoutput => true,
  require   => [ Package['gitlab-runner'], Exec['create_ssh_key'], ],
  notify    => Service['gitlab-runner'],
}
exec { 'register_runner_hpux':
  command   => "/usr/bin/gitlab-runner register --non-interactive --registration-token='${::gitlab_runner_registration_token}' --name='libstatgrab-ci-hpux' --url='https://gitlab.com/' --executor=ssh --ssh-host=p5p-hpux.procura.nl --ssh-port=22 --ssh-user=tdb --ssh-identity-file='${::ci_dir}/lsgci' --tag-list='libstatgrab-ci-hpux'",
  unless    => "/bin/grep libstatgrab-ci-hpux /etc/gitlab-runner/config.toml",
  logoutput => true,
  require   => [ Package['gitlab-runner'], Exec['create_ssh_key'], ],
  notify    => Service['gitlab-runner'],
}
