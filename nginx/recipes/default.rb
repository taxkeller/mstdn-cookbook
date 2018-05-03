#
# Cookbook:: nginx
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.
package "nginx" do
  :upgrade
end

template '/etc/nginx/sites-available/default' do
  source 'nginx.erb'
  owner 'root'
  group 'root'
  mode 0644
end

bash 'set_healthcheck' do
  user 'root'
  group 'root'
  code <<-EOH
    touch /var/www/html/healthcheck.txt
  EOH
end

service 'nginx' do
  action :restart
end
