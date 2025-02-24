#!/bin/bash

#get a public ip address
/root/yandex-cloud/bin/yc vpc address create --external-ipv4 zone=ru-central1-b --name external_ip

#declare an external ip variable
EXT_IP=$(/root/yandex-cloud/bin/yc vpc address get --name external_ip --format json --jq '.external_ipv4_address.address')

#create external network
/root/yandex-cloud/bin/yc vpc network create --name external-bastion-network

#create an external subnet
/root/yandex-cloud/bin/yc vpc subnet create --name bastion-external-segment --zone ru-central1-b --network-name external-bastion-network --range 172.16.17.0/28

#create internal network
/root/yandex-cloud/bin/yc vpc network create --name internal-bastion-network

#create an internal subnet
/root/yandex-cloud/bin/yc vpc subnet create --name bastion-internal-segment --zone ru-central1-b --network-name internal-bastion-network --range 172.16.16.0/24

#create an external security group
/root/yandex-cloud/bin/yc vpc security-group create --name external-bastion-sg --rule direction=ingress,port=22,protocol=tcp,v4-cidrs=[0.0.0.0/0], --network-name external-bastion-network

#declare an external security group variable
EXT_SG=$(/root/yandex-cloud/bin/yc vpc security-group get --name external-bastion-sg --format json --jq '.id')

#create an internal security group
/root/yandex-cloud/bin/yc vpc security-group create --name internal-bastion-sg --rule direction=ingress,port=22,protocol=tcp,v4-cidrs=[172.16.16.254/32] --rule direction=egress,port=22,protocol=tcp,predefined="self_security_group"  --network-name internal-bastion-network

#declare an internal security group variable
INT_SG=$(/root/yandex-cloud/bin/yc vpc security-group get --name internal-bastion-sg --format json --jq '.id')

#create bastion vm
/root/yandex-cloud/bin/yc compute instance create \
  --name bastion-vm \
  --zone ru-central1-b \
  --preemptible \
  --network-interface subnet-name=bastion-external-segment,nat-ip-version=ipv4,nat-address=${EXT_IP},security-group-ids=${EXT_SG} \
  --network-interface subnet-name=bastion-internal-segment,ipv4-address=172.16.16.254,security-group-ids=${INT_SG} \
  --ssh-key ~/.ssh/id_ed25519.pub \
  --create-boot-disk name=bastion-disk,type=network-hdd,size=10GB,image-folder-id=standard-images,image-id=fd8sk333i8jmpouraqok \
  --memory 2GB \
  --cores 2 \
  --platform standard-v3 \
  --core-fraction 20 \
  --hostname bastion-vm

/root/yandex-cloud/bin/yc compute instance create \
  --name vm01 \
  --zone ru-central1-b \
  --preemptible \
  --network-interface subnet-name=bastion-internal-segment,ipv4-address=auto,security-group-ids=${INT_SG} \
  --ssh-key ~/.ssh/id_ed25519.pub \
  --create-boot-disk name=vm01-disk,type=network-hdd,size=10GB,image-folder-id=standard-images,image-id=fd8sk333i8jmpouraqok \
  --memory 2GB \
  --cores 2 \
  --platform standard-v3 \
  --core-fraction 20 \
  --hostname vm-01

/root/yandex-cloud/bin/yc compute instance create \
  --name vm02 \
  --zone ru-central1-b \
  --preemptible \
  --network-interface subnet-name=bastion-internal-segment,ipv4-address=auto,security-group-ids=${INT_SG} \
  --ssh-key ~/.ssh/id_ed25519.pub \
  --create-boot-disk name=vm02-disk,type=network-hdd,size=10GB,image-folder-id=standard-images,image-id=fd8sk333i8jmpouraqok \
  --memory 2GB \
  --cores 2 \
  --platform standard-v3 \
  --core-fraction 20 \
  --hostname vm-02
