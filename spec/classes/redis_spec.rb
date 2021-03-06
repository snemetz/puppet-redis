require 'spec_helper'

describe 'redis' do

  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  let(:parser) { 'future' }

  it { should contain_class('singleton') }
  it { should contain_package('singleton_package_wget') }
  it { should contain_package('singleton_package_gcc') }

  context "with default param" do

    it do
      should contain_file('conf dir').with({
        'ensure'    => 'directory',
        'path'  => '/etc/redis',
      })
    end

    it do
      should contain_file('data dir').with({
        'ensure'    => 'directory',
        'path'  => '/var/lib/redis',
      })
    end

    it do
      should contain_exec('download redis').with({
        'cwd'     => '/tmp',
        'path'    => '/bin:/usr/bin',
        'command' => 'wget http://download.redis.io/releases/redis-2.8.8.tar.gz',
        'creates' => '/tmp/redis-2.8.8.tar.gz',
        'notify'  => 'Exec[untar redis]',
        'require' => 'Package[wget]',
      })
    end

    it do
      should contain_exec('untar redis').with({
        'cwd'     => '/tmp',
        'path'    => '/bin:/usr/bin',
        'command' => 'tar -zxvf redis-2.8.8.tar.gz',
        'creates' => '/tmp/redis-2.8.8/Makefile',
        'notify'  => 'Exec[install redis]',
      })
    end

    it do
      should contain_exec('install redis').with({
        'cwd'     => '/tmp/redis-2.8.8',
        'path'    => '/bin:/usr/bin',
        'command' => 'make && make install',
        'creates' => '/usr/local/bin/redis-server',
        'require' => 'Package[gcc]',
      })
    end

    it do
      should contain_file_line('sysctl').with({
        'path'    => '/etc/sysctl.conf',
        'line'    => 'vm.overcommit_memory = 1',
        'match'   => '^((vm.overcommit_memory = )[0-1]{1})$',
      })
    end

    it do
      should contain_exec('apply sysctl').with({
        'cwd'     => '/',
        'path'    => '/sbin:/bin:/usr/bin',
        'command' => 'sysctl vm.overcommit_memory=1',
      })
    end

    it do
      should contain_file_line('conf_redis_6379_daemonize').with({
        'path'    => '/etc/redis/6379.conf',
        'line'    => 'daemonize yes',
        'match'   => '^(#\\s)?(daemonize\\s)(((?!and)(?!192.168.1.100\\s10.0.0.1)(?!is\\sset)[A-Za-z0-9\\._\\-"/\\s]+)|(<master-password>)|(<masterip>\\s<masterport>)|(<bytes>))$',
        'require' => 'File[conf file redis_6379]',
        'notify'  => 'Service[redis redis_6379]',
      })
    end

    it do
      should contain_file_line('conf_redis_6379_port').with({
        'path'    => '/etc/redis/6379.conf',
        'line'    => 'port 6379',
        'match'   => '^(#\\s)?(port\\s)(((?!and)(?!192.168.1.100\\s10.0.0.1)(?!is\\sset)[A-Za-z0-9\\._\\-"/\\s]+)|(<master-password>)|(<masterip>\\s<masterport>)|(<bytes>))$',
        'require' => 'File[conf file redis_6379]',
        'notify'  => 'Service[redis redis_6379]',
      })
    end

    it do
      should contain_file_line('conf_redis_6379_pidfile').with({
        'path'    => '/etc/redis/6379.conf',
        'line'    => 'pidfile /var/run/redis_6379.pid',
        'match'   => '^(#\\s)?(pidfile\\s)(((?!and)(?!192.168.1.100\\s10.0.0.1)(?!is\\sset)[A-Za-z0-9\\._\\-"/\\s]+)|(<master-password>)|(<masterip>\\s<masterport>)|(<bytes>))$',
        'require' => 'File[conf file redis_6379]',
        'notify'  => 'Service[redis redis_6379]',
      })
    end

    it do
      should contain_file_line('conf_redis_6379_logfile').with({
        'path'    => '/etc/redis/6379.conf',
        'line'    => 'logfile /var/log/redis_6379.log',
        'match'   => '^(#\\s)?(logfile\\s)(((?!and)(?!192.168.1.100\\s10.0.0.1)(?!is\\sset)[A-Za-z0-9\\._\\-"/\\s]+)|(<master-password>)|(<masterip>\\s<masterport>)|(<bytes>))$',
        'require' => 'File[conf file redis_6379]',
        'notify'  => 'Service[redis redis_6379]',
      })
    end

    it do
      should contain_file_line('conf_redis_6379_dir').with({
        'path'    => '/etc/redis/6379.conf',
        'line'    => 'dir /var/lib/redis/6379',
        'match'   => '^(#\\s)?(dir\\s)(((?!and)(?!192.168.1.100\\s10.0.0.1)(?!is\\sset)[A-Za-z0-9\\._\\-"/\\s]+)|(<master-password>)|(<masterip>\\s<masterport>)|(<bytes>))$',
        'require' => 'File[conf file redis_6379]',
        'notify'  => 'Service[redis redis_6379]',
      })
    end

  end

  context "with sysctl param" do
    let(:params) { {:sysctl => false} }

    it do
      should_not contain_file_line('sysctl')
    end
    it do
      should_not contain_exec('apply sysctl')
    end

  end

end
