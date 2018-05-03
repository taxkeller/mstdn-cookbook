#
# Cookbook:: docker
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.
bash 'get_docker_package' do
  user 'root'
  group 'root'
  code <<-EOH
    curl -sSL https://get.docker.com/ | sh
    systemctl enable docker
    systemctl start docker
  EOH
end

bash 'get_docker_compose' do
  user 'root'
  group 'root'
  code <<-EOH
    curl -L https://github.com/docker/compose/releases/download/1.12.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  EOH
end

group 'docker' do
  action :modify
  members ['mastodon']
  append true
end
