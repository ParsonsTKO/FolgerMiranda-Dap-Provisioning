#cloud-config
apt_upgrade: false
preserve_hostname: true
runcmd:
  - hostname "${name}"
  - echo "127.0.0.1 ${name}" >> /etc/hosts
  - echo "${name}" > /etc/hostname
  - echo ECS_CLUSTER=FOLGERDAP >> /etc/ecs/ecs.config
  - cloud-init-per once docker_options echo 'OPTIONS="$${OPTIONS} --storage-opt dm.basesize=100G"' >> /etc/sysconfig/docker
  - sudo yum install -y nfs-utils
  - sudo mkdir -p /mnt/efs/folgerdap
  - echo 'fs-62639b1b.efs.us-east-2.amazonaws.com:/ /mnt/efs/folgerdap nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0' | sudo tee -a /etc/fstab
  - sudo mount --all
  - sudo stop ecs
  - sudo service docker restart
  - sudo start ecs
  - sudo service awslogs restart
  - sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
