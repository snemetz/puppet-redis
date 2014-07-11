require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'coveralls'
# Coveralls broke when codeclimate was added
#require 'codeclimate-test-reporter'
#CodeClimate::TestReporter.start

Coveralls.wear!

RSpec.configure do |c|
  c.default_facts = {
    :osfamily        => 'RedHat',
    :operatingsystem => 'CentOS',
    :architecture    => 'x86_64',
  }
end
