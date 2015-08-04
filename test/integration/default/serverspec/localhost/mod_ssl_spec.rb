#
# Copyright (c) 2014 OneHealth Solutions, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require "#{ENV['BUSSER_ROOT']}/../kitchen/data/serverspec_helper"

describe 'ga-apache2::mod_ssl' do

  # it 'installs the mod_ssl package on RHEL distributions' do
  #   skip unless %w(rhel fedora).include?(node['platform_family'])
  #   describe package('mod_ssl') do
  #     it { should be_installed }
  #   end
  # end

  expected_module = 'ssl'
  subject(:available) { file("#{property[:apache][:dir]}/mods-available/#{expected_module}.load") }
  it "mods-available/#{expected_module}.load is accurate" do
    expect(available).to be_file
    expect(available).to be_mode 644
    expect(available.content).to match "LoadModule #{expected_module}_module #{property[:apache][:libexec_dir]}/mod_#{expected_module}.so\n"
  end

  subject(:enabled) { file("#{property[:apache][:dir]}/mods-enabled/#{expected_module}.load") }
  it "mods-enabled/#{expected_module}.load is a symlink to mods-available/#{expected_module}.load" do
    expect(enabled).to be_linked_to("../mods-available/#{expected_module}.load")
  end

  subject(:loaded_modules) { command("APACHE_LOG_DIR=#{property[:apache][:log_dir]} #{property[:apache][:binary]} -M") }
  it "#{expected_module} is loaded" do
    expect(loaded_modules.exit_status).to eq 0
    expect(loaded_modules.stdout).to match(/#{expected_module}_module/)
  end

  subject(:portsconf) { file("#{property[:apache][:dir]}/ports.conf") }
  it 'ports.conf specifies listening on port 443' do
    expect(portsconf).to contain(/^Listen .*[: ]443$/)
  end

  subject(:configfile) { file("#{property[:apache][:dir]}/mods-enabled/#{expected_module}.conf") }
  it "mods-enabled/#{expected_module}.conf adds SSL directives" do
    expect(configfile).to be_file
    # expect(configfile).to contain(/SSLCipherSuite #{Regexp.escape(property[:apache][:mod_ssl][:cipher_suite])}$/)
  end
end
