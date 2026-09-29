 #!/bin/bash

# set -euo pipefail

 component=$1

environment=$2

# echo "Installing Ansible..."
 dnf install ansible -y
 dnf install python3-pip -y
 python3 -m pip install boto3 botocore

# echo "Running ansible-pull for $component..."

# ansible-pull -U https://github.com/chandu-hash15/Terra_Ansi_Roles-_Integration.git\
#   -i localhost, \
#   -e "component=$component" \
#   main.yaml -vv

 REPO_URL=https://github.com/chandu-hash15/Terra_Ansi_Roles_Integration.git

 REPO_DIR=/opt/roboshop/ansible

 ANSIBLE_DIR=Terra_Ansi_Roles_Integration

 mkdir -p $REPO_DIR

 mkdir -p /var/roboshop/ansible

 touch ansible.log


 cd $REPO_DIR

 # check if ansible directory is already exists or not

 if [ -d   $ANSIBLE_DIR ]; then 
    

      cd  $ANSIBLE_DIR

      git pull

  else 

      git clone $REPO_URL

      cd  $ANSIBLE_DIR

  fi

  ansible-playbook \
  -e "component=$component env=$environment" \
  main.yaml


