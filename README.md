# wordpress-cookbook

## Prerequisite

- Install Homebrew
```
$ 
```

- Install AWS-Cli
```
$ brew install awscli
```

- Set your creadential
```
$ cat ~/.aws/credentials
[default]
aws_access_key_id = (your key id)
aws_secret_access_key = (your secrete key)
region = (your region)
```

## How to set up

### Set environment variables

```
# Copy template file
$ cp .env/init/params.sample .env/init/params

# Input your aws account number
$ vim .env/init/params

# Set environment
$ cat .env/init/params >> ~/.bashrc
$ source ~/.bashrc
```

### Set layer configuration

```
# Copy template file
$ cp .env/layer/layer.json.sample .env/layer/layer.json

# Input your domain
$ vim .env/layer/layer.json
```

### EC2

- Create Key pair
```
$ mkdir ~/.ssh
$ aws ec2 create-key-pair --key-name $key_name | grep KeyMaterial | cut -d\" -f4 | perl -pe 's/\\n/\n/g' > ~/.ssh/$key_name.pem
$ chmod 400 ~/.ssh/$key_name.pem
```

### IAM

- Create Role
```
$ aws iam create-role --role-name WatchMstdnInstance --assume-role-policy-document file://.env/roles/instance-role.json
$ aws iam create-role --role-name OpsworksMstdnService --assume-role-policy-document file://.env/roles/opsworks-role.json
```

- Create User
```
$ aws iam create-user --user-name mstdn
$ aws iam create-access-key --user-name mstdn
$ aws iam attach-user-policy --user-name mstdn --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

- Create Policy
```
$ aws iam create-instance-profile --instance-profile-name OpsworksMstdnInstance
$ aws iam create-policy --policy-name aws-opsworks-mstdn-policy --policy-document file://.env/policies/opsworks.json
```
- Attach Policy
```
$ aws iam attach-role-policy --role-name WatchMstdnInstance --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
$ aws iam attach-role-policy --role-name OpsworksMstdnService --policy-arn arn:aws:iam::$my_aws_account:policy/aws-opsworks-mstdn-policy
$ aws iam add-role-to-instance-profile --instance-profile-name OpsworksMstdnInstance --role-name WatchMstdnInstance
```

### Opsworks
- Create stack
```
$ aws opsworks create-stack --name $stack_name --service-role-arn arn:aws:iam::"$my_aws_account":role/OpsworksMstdnService --default-instance-profile-arn arn:aws:iam::"$my_aws_account":instance-profile/OpsworksMstdnInstance --stack-region ap-southeast-1 --default-os 'Ubuntu 16.04 LTS' --configuration-manager Name='Chef',Version=12 --custom-cookbooks-source Type=git,Url=https://github.com/taxkeller/mstdn-cookbook.git --use-custom-cookbooks --default-root-device-type ebs | grep StackId | cut -d\" -f4 > .env/opsworks-ids/stack-id
```

- Create Layer
```
$ aws opsworks create-layer --stack-id `cat .env/opsworks-ids/stack-id` --type custom --name mastodon --shortname mstdn --custom-json file://.env/layer/layer.json --auto-assign-public-ips --custom-recipes Setup=environment,docker,nginx,git,awslogs,Deploy=deploy | grep LayerId | cut -d\" -f4 > .env/opsworks-ids/layer-id
```

- Create App

```
$ aws opsworks create-app --stack-id `cat .env/opsworks-ids/stack-id` --name mastodon --type other --app-source Type=git,Url=https://github.com/taxkeller/mastodon.git --environment file://.env/app/environment.json | grep AppId | cut -d\" -f4 > .env/opsworks-ids/app-id
```

- Create Instance
```
$ aws opsworks create-instance --stack-id `cat .env/opsworks-ids/stack-id` --layer-ids `cat .env/opsworks-ids/layer-id` --instance-type t2.medium --ssh-key-name $key_name --block-device-mapping DeviceName=ROOT_DEVICE,Ebs="{VolumeSize=20,VolumeType=gp2}" | grep InstanceId | cut -d\" -f4 > .env/opsworks-ids/instance-id
```

- Start Instance
```
$ aws opsworks start-instance --instance-id `cat .env/opsworks-ids/instance-id`
```

## How to remove

- Remove opwsorks

```
$ aws opsworks stop-instance --instance-id `cat .env/opsworks-ids/instance-id`
$ aws opsworks delete-instance --instance-id `cat .env/opsworks-ids/instance-id`
$ aws opsworks delete-layer --layer-id `cat .env/opsworks-ids/layer-id`
$ aws opsworks delete-stack --stack-id `cat .env/opsworks-ids/stack-id`
```

- Remove role & policies

```
$ aws iam remove-role-from-instance-profile --instance-profile-name OpsworksMstdnInstance --role-name WatchMstdnInstance
$ aws iam detach-role-policy --role-name OpsworksMstdnService --policy-arn arn:aws:iam::$my_aws_account:policy/aws-opsworks-mstdn-policy
$ aws iam detach-role-policy --role-name WatchMstdnInstance --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
$ aws iam delete-policy --policy-arn arn:aws:iam::$my_aws_account:policy/aws-opsworks-mstdn-policy
$ aws iam delete-instance-profile --instance-profile-name OpsworksMstdnInstance
$ aws iam delete-role --role-name OpsworksMstdnService
$ aws iam delete-role --role-name WatchMstdnInstance
```

- Remove key

```
$ aws ec2 delete-key-pair --key-name $key_name
```
