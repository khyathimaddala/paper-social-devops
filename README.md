

## Overview

Welcome to the PaperSocial DevOps Assesment! This repository contains the infrastructure and application deployment scripts for the PaperSocial application on AWS, utilizing GitHub Actions for CI/CD, Ansible for configuration management, and Amazon CloudWatch for monitoring. This README provides a detailed guide to set up, deploy, and monitor the project.

## Project Structure

- `.github/workflows/deploy.yml`: GitHub Actions workflow for automated deployment.
- `ansible/inventory/hosts`: Ansible inventory file defining target hosts.
- `ansible/playbooks/roles/web/tasks/iam_setup.yml`: Ansible playbook for IAM role and policy setup.
- `ansible/playbooks/deploy.yml`: Main Ansible playbook for application deployment.
- `app/requirements.txt`: Python dependencies for the PaperSocial Flask app.

## Prerequisites

- **AWS Account**: With permissions to create IAM roles, EC2 instances, and CloudWatch resources.
- **GitHub Account**: To manage the repository and secrets.
- **SSH Key**: A private key (e.g., `paper-social-key.pem`) for EC2 access.
- **Python 3.x**: Installed locally for testing Ansible.
- **Ansible**: Version 2.18.4 or later, with `community.aws` collection (9.1.0).
- **AWS CLI**: Configured with access/secret keys and region (us-east-1).

## Setup Instructions

### 1. Configure GitHub Secrets
- Add the following secrets in your GitHub repository under **Settings > Secrets and variables > Actions**:
  - `AWS_ACCESS_KEY_ID`: Your AWS access key.
  - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key.
  - `SSH_PRIVATE_KEY`: Contents of your `paper-social-key.pem` file.

### 2. Install Dependencies
- Clone the repository:
  ```bash
  git clone https://github.com/your-username/paper-social-devops.git
  cd paper-social-devops
  ```
- Install Python dependencies and Ansible collections:
  ```bash
  python -m pip install --upgrade pip
  pip install ansible boto3 awscli
  ansible-galaxy collection install community.aws:==9.1.0 --force
  pip install -r app/requirements.txt
  ```

### 3. Configure Inventory
- Edit `ansible/inventory/hosts` to include your EC2 instance IPs (e.g., 18.212.179.36, 54.167.152.195):
  ```ini
  [web]
  18.212.179.36
  54.167.152.195
  ```

### 4. Set Up EC2 Instances
- Launch EC2 instances in us-east-1 with the `PaperSocialCloudWatchRole` attached via an instance profile.
- Install the CloudWatch Agent on each instance:
  ```bash
  sudo yum install -y amazon-cloudwatch-agent
  ```
- Configure the agent (see Monitoring section below) and start it:
  ```bash
  sudo systemctl start amazon-cloudwatch-agent
  ```

## Deployment

### Automated Deployment via GitHub Actions
- Push changes to the `main` branch to trigger the workflow.
- The `deploy.yml` workflow performs:
  1. Checks out the code.
  2. Sets up Python and installs dependencies.
  3. Configures AWS CLI and SSH keys.
  4. Creates IAM role and policy via `iam_setup.yml`.
  5. Deploys the application to EC2 instances.
  6. Verifies deployment via ALB and CloudWatch Agent status.

### Manual Deployment
- Run the playbook locally:
  ```bash
  ansible-playbook -i ansible/inventory/hosts ansible/playbooks/deploy.yml --private-key=~/.ssh/paper-social-key.pem --ssh-common-args='-o IdentitiesOnly=yes' -v
  ```

### Verify Deployment
- Check application accessibility:
  ```bash
  curl http://paper-social-alb-1896686171.us-east-1.elb.amazonaws.com
  ```
- Expected response: Welcome to Paper.Social!

## Monitoring with Amazon CloudWatch

### Configuration
- The `PaperSocialCloudWatchRole` IAM role is created with a policy (`CloudWatchAgentPolicy`) allowing `logs:CreateLogStream` and `logs:PutLogEvents`.
- Configure the CloudWatch Agent on EC2 instances with a JSON file (e.g., `/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`):
  ```json
  {
    "agent": {
      "run_as_user": "cwagent"
    },
    "metrics": {
      "namespace": "PaperSocialMetrics",
      "metrics_collected": {
        "cpu": {
          "measurement": ["usage_active"]
        },
        "mem": {
          "measurement": ["used"]
        }
      }
    },
    "logs": {
      "logs_collected": {
        "files": {
          "collect_list": [
            {
              "file_path": "/var/log/messages",
              "log_group_name": "/aws/ec2/messages",
              "log_stream_name": "{instance_id}"
            }
          ]
        }
      }
    }
  }
  ```
- Apply the configuration:
  ```bash
  sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
  ```

### Verification
- **Metrics**: In AWS Console > CloudWatch > Metrics, check `PaperSocialMetrics` for CPU/memory data.
- **Logs**: In AWS Console > CloudWatch > Logs, view `/aws/ec2/messages` for log entries.
- **Agent Status**: SSH and run:
  ```bash
  sudo systemctl status amazon-cloudwatch-agent
  ```

## Best Practices

- **Version Pinning**: Fixed `community.aws` to 9.1.0 for consistency.
- **Security**: Used GitHub Secrets for credentials and restricted SSH access.
- **Idempotency**: Ansible playbooks support safe re-runs.
- **Monitoring**: Integrated CloudWatch for real-time insights.
- **Debugging**: Added workflow debug steps to troubleshoot issues.

## Troubleshooting

- **Module Errors**: If `iam_policy` fails, try `community.aws:==8.0.0` or check `ansible-doc -l | grep community.aws`.
- **Deployment Issues**: Verify EC2 connectivity and ALB configuration.
- **Agent Problems**: Ensure IAM role is attached and config file is valid .

