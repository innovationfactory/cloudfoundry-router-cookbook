#
# Cookbook Name:: cloudfoundry-router
# Recipe:: ssl
#
# Copyright 2012, Ruben Koster
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

def listen_addresses
  node['network']['interfaces'].map do |iface, data| 
    data["addresses"].select { |addr, data| data["family"] == "inet" }.keys[0]
  end
end

listen_addresses.each do |ip|
  q = "id:#{ip.gsub('.', '_')}*"
  search(:addresses, q).each do |dbag|
    dbag["cert"]
    spath = File.join(node['nginx']['path'], "conf", "servers")
    cpath = node['cloudfoundry_router']['ssl']['certs_dir']
    kpath = node['cloudfoundry_router']['ssl']['keys_dir']
    template "location-nginx.conf" do
      path File.join(spath, "#{dbag["cert"]}.conf")
      source "ssl-server-nginx.conf.erb"
      owner node['cloudfoundry_common']['user']
      mode 0644
      variables(
        :address => ip,
        :cert_file => File.join(cpath, "#{dbag["cert"]}.crt"),
        :key_file => File.join(kpath, "#{dbag["cert"]}.key")
        )
      notifies :restart, "service[router-nginx]"
    end
  end
end


