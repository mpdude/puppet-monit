# monit::config
# @api private
#
# This class handles the configuration files.
#
class monit::config {

  if $caller_module_name != $module_name {
    warning("${name} is not part of the public API of the ${module_name} module and should not be directly included in the manifest.")
  }

  # Monit conf file and directory.
  file { $monit::conf_file:
    ensure  => present,
    mode    => '0600',
    content => template('monit/conf_file.erb'),
  }
  file { $monit::conf_dir:
    ensure  => directory,
    recurse => true,
    purge   => $monit::conf_purge,
  }

  file { "${monit::conf_dir}/00_monit_config":
    ensure  => present,
    content => template('monit/conf_file_overrides.erb'),
  }

  monit::check::system {$::facts['networking']['fqdn']:
    ensure   => $monit::system_check_ensure,
    priority => '10',
    group    => 'system',
    order    => 0,
    tests    => parseyaml(template('monit/system_test_resources.erb')),
  }
  monit::check::filesystem { 'fs':
    ensure   => $monit::system_check_ensure,
    priority => '10',
    group    => 'system',
    bundle   => $::facts['networking']['fqdn'],
    order    => 1,
    paths    => $monit::system_fs,
    tests    => [
      {'type' => 'fsflags'},
      {'type' => 'space', 'operator' => '>', 'value' => $monit::system_fs_space_usage },
      {'type' => 'inode', 'operator' => '>', 'value' => $monit::system_fs_inode_usage },
    ]
  }

  # Additional checks.
  if ($monit::hiera_merge_strategy == 'hiera_hash') {
    $mychecks = hiera_hash('monit::checks', {})
  }
  else {
    $mychecks = $monit::checks
  }
  create_resources('monit::check', $mychecks)
}
