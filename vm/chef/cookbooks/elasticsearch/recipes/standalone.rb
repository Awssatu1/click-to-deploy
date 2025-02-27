# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'openjdk11'

apt_update 'update' do
  action :update
  retries 5
  retry_delay 30
end

package 'Install Packages' do
  package_name node['elasticsearch']['packages']
  action :install
end

# Configure elasticsearch repository
apt_repository 'add_elastic_co_repo' do
  uri node['elasticsearch']['repository_url']
  components ['stable', 'main']
  keyserver node['elasticsearch']['keyserver_url']
  distribution false
  trusted true
end

apt_update 'update' do
  action :update
  retries 5
  retry_delay 30
end

# Install elasticsearch
package 'elasticsearch' do
  version node['elasticsearch']['version']
  action :install
end

# Copy configuration templates
cookbook_file '/etc/elasticsearch/elasticsearch.yml.template' do
  source 'etc/elasticsearch/elasticsearch.yml.template'
  owner 'root'
  group 'root'
  mode '0640'
end

cookbook_file '/etc/default/elasticsearch.template' do
  source 'etc/default/elasticsearch.template'
  owner 'root'
  group 'root'
  mode '0640'
end

# Update service configuration
execute 'update-rc.d elasticsearch defaults 95 10'

# Certshare service
cookbook_file '/etc/systemd/system/certshare.service' do
  source 'certshare.service'
  owner 'root'
  group 'root'
  mode 0664
  action :create
end

service 'certshare.service' do
  action [ :enable, :stop ]
end

# Patch for including ssl feature for elasticsearch
cookbook_file '/opt/c2d/patch-ssl' do
  source 'patch-ssl'
  owner 'root'
  group 'root'
  mode 0664
  action :create
end

# Download elasticsearch source files
remote_file '/usr/src/elasticsearch_src.tar.gz' do
  source "https://github.com/elastic/elasticsearch/archive/v#{node['elasticsearch']['version']}.tar.gz"
  mode '0644'
  action :create
  retries 5
  retry_delay 30
end
