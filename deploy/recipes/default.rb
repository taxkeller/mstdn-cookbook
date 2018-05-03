#
# Cookbook:: deploy
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

search('aws_opsworks_app').each do |app|
  git '/home/mastodon/live' do
    repository app[:app_source][:url]
    reference 'develop'
    user 'mastodon'
    group 'mastodon'
  end

  template '/home/mastodon/live/docker-compose.yml' do
    backup false
    source 'docker-compose.yml.erb'
    owner 'mastodon'
    group 'mastodon'
    mode 0400
    variables ({
      :hostname                 => `hostname`.strip,
      :awslogs_region           => app['environment']['awslogs_region'],
      :awslogs_web_group        => app['environment']['awslogs_web_group'],
      :awslogs_streaming_group  => app['environment']['awslogs_streaming_group'],
      :awslogs_sidekiq_group    => app['environment']['awslogs_sidekiq_group'],
    })
  end

  template '/home/mastodon/live/.env.production' do
    backup false
    source 'env.production.erb'
    owner 'mastodon'
    group 'mastodon'
    mode 0400
    variables ({
      :redis_host             => app['environment']['redis_host'],
      :db_host                => app['environment']['db_host'],
      :db_user                => app['environment']['db_user'],
      :db_name                => app['environment']['db_name'],
      :db_pass                => app['environment']['db_pass'],
      :es_enabled             => app['environment']['es_enabled'],
      :es_host                => app['environment']['es_host'],
      :local_domain           => app['environment']['local_domain'],
      :secret_key_base        => app['environment']['secret_key_base'],
      :otp_secret             => app['environment']['otp_secret'],
      :vapid_private_key      => app['environment']['vapid_private_key'],
      :vapid_public_key       => app['environment']['vapid_public_key'],
      :default_locale         => app['environment']['default_locale'],
      :smtp_server            => app['environment']['smtp_server'],
      :smtp_login             => app['environment']['smtp_login'],
      :smtp_password          => app['environment']['smtp_password'],
      :smtp_from_address      => app['environment']['smtp_from_address'],
      :s3_enabled             => app['environment']['s3_enabled'],
      :s3_bucket              => app['environment']['s3_bucket'],
      :aws_access_key_id      => app['environment']['aws_access_key_id'],
      :aws_secret_access_key  => app['environment']['aws_secret_access_key'],
      :s3_region              => app['environment']['s3_region'],
      :s3_hostname            => app['environment']['s3_hostname'],
      :s3_cloudfront_host     => app['environment']['s3_cloudfront_host'],
      :slack_url              => app['environment']['slack_url'],
      :facebook_api           => app['environment']['facebook_api'],
      :facebook_app_id        => app['environment']['facebook_app_id'],
      :facebook_app_secret    => app['environment']['facebook_app_secret'],
    })
  end
end

bash 'build' do
  user 'root'
  group 'root'
  code <<-EOH
    docker-compose --project-directory /home/mastodon/live -f /home/mastodon/live/docker-compose.yml build
  EOH
end

bash 'migrate' do
  user 'root'
  group 'root'
  code <<-EOH
    docker-compose --project-directory /home/mastodon/live -f /home/mastodon/live/docker-compose.yml run --rm web rails db:migrate
  EOH
end

bash 'compile' do
  user 'root'
  group 'root'
  code <<-EOH
    docker-compose --project-directory /home/mastodon/live -f /home/mastodon/live/docker-compose.yml run --rm web rails assets:precompile
  EOH
end

bash 'run' do
  user 'root'
  group 'root'
  code <<-EOH
    docker-compose --project-directory /home/mastodon/live -f /home/mastodon/live/docker-compose.yml up -d
  EOH
end

bash 'garbage' do
  user 'root'
  group 'root'
  code <<-EOH
    docker images -aq --filter dangling=true
    docker-colume ls -f dangling=true | awk '{print "/var/lib/docker/volumes/" $2}' | xargs rm -rf
  EOH
end
