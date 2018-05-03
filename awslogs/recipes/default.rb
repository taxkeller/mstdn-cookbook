#
# Cookbook:: awslogs
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.
directory '/usr/local/etc/awslogs' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

template '/usr/local/etc/awslogs.conf' do
  backup false
  source 'awslogs.conf.erb'
  owner 'root'
  group 'root'
  mode 0400
end

bash 'setup_awslogs' do
  user 'root'
  group 'root'
  code <<-EOH
    wget https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -P /usr/local/bin
    python3 /usr/local/bin/awslogs-agent-setup.py --region ap-southeast-1 --non-interactive --configfile /usr/local/etc/awslogs.conf
    service awslogs start
  EOH
end
