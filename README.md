# Reference
NiFi secure+autoscaling cluster built automatically in AWS via Terraform+Ansible. RHEL7 or Ubuntu (20.04 or 18.04) base.

# Requirements
- An AWS account
- Follow Step-by-Step (compatible with Windows and Ubuntu)

# Step-by-Step Terraform Deployment 
Windows Users install WSL (Windows Subsystem Linux)
```
#############################
## Windows Subsystem Linux ##
#############################
# Launch an ELEVATED Powershell prompt (right click -> Run as Administrator)

# Enable Windows Subsystem Linux
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Reboot your Windows PC
shutdown /r /t 5

# After reboot, launch a REGULAR Powershell prompt (left click).
# Do NOT proceed with an ELEVATED Powershell prompt.

# Download the Ubuntu 1804 package from Microsoft
curl.exe -L -o ubuntu-1804.appx https://aka.ms/wsl-ubuntu-1804
 
# Rename the package
Rename-Item ubuntu-1804.appx ubuntu-1804.zip
 
# Expand the zip
Expand-Archive ubuntu-1804.zip ubuntu-1804
 
# Change to the zip directory
cd ubuntu-1804
 
# Execute the ubuntu 1804 installer
.\ubuntu1804.exe
 
# Create a username and password when prompted
```
Install Terraform, Git, and create an SSH key pair
```
#############################
##  Terraform + Git + SSH  ##
#############################
# Add terraform's apt key (enter previously created password at prompt)
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
 
# Add terraform's apt repository
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
 
# Install terraform and git
sudo apt-get update && sudo apt-get -y install terraform git
 
# Clone the project
git clone https://github.com/chadgeary/nifi

# Create SSH key pair (RETURN for defaults)
ssh-keygen
```

Install the AWS cli and create non-root AWS user. An [AWS account](https://portal.aws.amazon.com/billing/signup) is required to continue.
```
#############################
##          AWS            ##
#############################
# Open powershell and start WSL
wsl

# Change to home directory
cd ~

# Install python3 pip
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y install python3-pip

# Install awscli via pip
pip3 install --user --upgrade awscli

# Create a non-root AWS user in the AWS web console with admin permissions
# This user must be the same user running terraform apply
# Create the user at the AWS Web Console under IAM -> Users -> Add user -> Check programmatic access and AWS Management console -> Attach existing policies -> AdministratorAccess -> copy Access key ID and Secret Access key
# See for more information: https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html#getting-started_create-admin-group-console

# Set admin user credentials
~/.local/bin/aws configure

# Validate configuration
~/.local/bin/aws sts get-caller-identity 

# For troubleshooting EC2 instances, use the SSM Session Manager plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o ~/session-manager-plugin.deb
sudo dpkg -i ~/session-manager-plugin.deb

# and set the SSH helper configuration for SSM Session Manager
tee -a ~/.ssh/config << EOM
host i-* mi-*
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
EOM
```

Customize the deployment - See variables section below
```
# Change to the project's aws directory in powershell (use ~/nifi/ubuntu1804/ for ubuntu)
cd ~/nifi/rhel7/

# Open File Explorer in a separate window
# Navigate to rhel or ubuntu project directory - change \chad\ to your WSL username
%HOMEPATH%\ubuntu-1804\rootfs\home\chad\nifi\rhel7

# Edit the nifi.tfvars file using notepad and save
```

Deploy
```
# In powershell's WSL window, change to the project's aws directory
cd ~/nifi/rhel7/

# Initialize terraform and apply the terraform state
terraform init
terraform apply -var-file="nifi.tfvars"

# If permissions errors appear, fix with the below command and re-run the terraform apply.
sudo chown $USER nifi.tfvars && chmod 600 nifi.tfvars

# Note the outputs from terraform after the apply completes

# Wait for the virtual machine to become ready (Ansible will setup the services for us). NiFi can take 30+ minutes to initialize.
```

# Variables
```
# instance_key
# a public SSH key for SSH access to the instance via user `ubuntu`.
# cat ~/.ssh/id_rsa.pub

# mgmt_cidr
# an IP range granted webUI, EC2 SSH access.

# kms_manager
# The AWS username (not root) granted access to read configuration files in S3.
```

# Post-Deployment
* Check the [State Manager](https://console.aws.amazon.com/systems-manager/state-manager) for `Status: Complete`
* Check the [Load Balancer](https://us-east-2.console.aws.amazon.com/ec2/v2/home?LoadBalancers#LoadBalancers:sort=loadBalancerName) for `Status: InService`

