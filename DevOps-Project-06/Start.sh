#!/bin/bash
set -e

KEY_PATH="$HOME/my-key"

echo "🔑 Checking SSH Key..."
if [ ! -f "$KEY_PATH" ]; then
    echo "❌ Error: Key file not found at $KEY_PATH"
    exit 1
fi
chmod 400 "$KEY_PATH"

echo "🚀 1. Building AWS Infrastructure with Terraform..."
cd terraform
terraform init
terraform apply -auto-approve

# استخراج الـ IPs تلقائياً
ANSIBLE_IP=$(terraform output -raw ansible_controller_public_ip)
MASTER_IP=$(terraform output -raw jenkins_master_public_ip)
AGENT_IP=$(terraform output -raw jenkins_agent_public_ip)
cd ..

echo "--------------------------------------------------"
echo "Ansible Controller IP : $ANSIBLE_IP"
echo "Jenkins Master IP     : $MASTER_IP"
echo "Jenkins Agent IP      : $AGENT_IP"
echo "--------------------------------------------------"

echo "⏳ Waiting 30 seconds for AWS EC2 instances to initialize SSH..."
sleep 30

echo "🔑 2. Copying SSH key to Ansible Controller..."
scp -o StrictHostKeyChecking=no -i "$KEY_PATH" "$KEY_PATH" ubuntu@$ANSIBLE_IP:~/.ssh/id_rsa

echo "⚙️ 3. Configuring Ansible Controller and testing connections..."
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@$ANSIBLE_IP << EOF
  chmod 600 ~/.ssh/id_rsa
  sudo apt update && sudo apt install -y ansible
  mkdir -p ~/ansible-jenkins
  
  cat << 'EOT' > ~/ansible-jenkins/inventory.ini
[jenkins-master]
master ansible_host=$MASTER_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[jenkins-agents]
agent1 ansible_host=$AGENT_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
EOT

  # Accept SSH Host Keys
  ssh -o StrictHostKeyChecking=no ubuntu@$MASTER_IP "echo Master SSH OK" || true
  ssh -o StrictHostKeyChecking=no ubuntu@$AGENT_IP "echo Agent SSH OK" || true

  # Test Ansible Ping
  echo "📡 Running Ansible Ping Test..."
  ansible all -i ~/ansible-jenkins/inventory.ini -m ping
EOF

echo "🎉 Everything is up, connected, and ready for deployment!"