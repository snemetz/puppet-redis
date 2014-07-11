require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'coveralls'
require 'codeclimate-test-reporter'

Coveralls.wear!
CodeClimate::TestReporter.start

RSpec.configure do |c|
  c.default_facts = {
    :osfamily        => 'RedHat',
    :operatingsystem => 'CentOS',
    :architecture    => 'x86_64',
  }
end
