terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
  }
}

provider "azurerm" {
  features {}

  skip_provider_registration = true
}

# Existing Azure lab resource group
data "azurerm_resource_group" "jenkins_rg" {
  name = "1-612cd029-playground-sandbox"
}

# Virtual Network
resource "azurerm_virtual_network" "jenkins_vnet" {
  name                = "jenkins-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.jenkins_rg.location
  resource_group_name = data.azurerm_resource_group.jenkins_rg.name
}

# Subnet
resource "azurerm_subnet" "jenkins_subnet" {
  name                 = "jenkins-subnet"
  resource_group_name  = data.azurerm_resource_group.jenkins_rg.name
  virtual_network_name = azurerm_virtual_network.jenkins_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "jenkins_nsg" {
  name                = "jenkins-nsg"
  location            = data.azurerm_resource_group.jenkins_rg.location
  resource_group_name = data.azurerm_resource_group.jenkins_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Jenkins"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IP
resource "azurerm_public_ip" "jenkins_ip" {
  name                = "jenkins-public-ip"
  location            = data.azurerm_resource_group.jenkins_rg.location
  resource_group_name = data.azurerm_resource_group.jenkins_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface
resource "azurerm_network_interface" "jenkins_nic" {
  name                = "jenkins-nic"
  location            = data.azurerm_resource_group.jenkins_rg.location
  resource_group_name = data.azurerm_resource_group.jenkins_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jenkins_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins_ip.id
  }
}

# Connect Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "jenkins_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.jenkins_nic.id
  network_security_group_id = azurerm_network_security_group.jenkins_nsg.id
}

# Jenkins Virtual Machine
resource "azurerm_linux_virtual_machine" "jenkins_vm" {
  name                = "jenkins-vm"
  resource_group_name = data.azurerm_resource_group.jenkins_rg.name
  location            = data.azurerm_resource_group.jenkins_rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.jenkins_nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(pathexpand("~/.ssh/id_rsa.pub"))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash

    apt-get update

    apt-get install -y \
      fontconfig \
      openjdk-21-jre \
      git \
      curl \
      wget \
      ca-certificates

    # Install Docker
    install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      -o /etc/apt/keyrings/docker.asc

    chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      > /etc/apt/sources.list.d/docker.list

    apt-get update

    apt-get install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    # Install Jenkins
    wget -O /etc/apt/keyrings/jenkins-keyring.asc \
      https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
      > /etc/apt/sources.list.d/jenkins.list

    apt-get update
    apt-get install -y jenkins

    # Allow Jenkins to use Docker
    usermod -aG docker jenkins

    systemctl enable jenkins
    systemctl restart jenkins
  EOF
  )
}

# Show Jenkins public IP after deployment
output "jenkins_public_ip" {
  value = azurerm_public_ip.jenkins_ip.ip_address
}