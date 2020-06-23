variable "subnet_range" {
}

variable "location" {
}

variable "cluster_name" {
}

variable "name_prefix" {
}

variable "public_ssh_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "tags" {
  type    = map(string)
  default = {}
}

provider "azurerm" {
  version = "=2.14.0"
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.name_prefix != "" ? "${var.name_prefix}-${var.cluster_name}" : var.cluster_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.cluster_name}"
  address_space       = [var.subnet_range]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = merge(
    var.tags,
    {
      "Name"    = var.cluster_name
      "Cluster" = var.cluster_name
    },
  )
}

resource "azurerm_subnet" "subnet" {
  name                 = "dcos-${var.cluster_name}"
  address_prefixes     = [var.subnet_range]
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "test" {
  name                = "dcos-${var.cluster_name}-test"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "sshRule"
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
    name                         = "allowAllInternal"
    priority                     = 101
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = [var.subnet_range]
    destination_address_prefixes = [var.subnet_range]
  }

  security_rule {
    name                       = "allowAllOut"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

module "dcos-instances" {
  source = "../../"

  num                       = 1
  location                  = var.location
  public_ssh_key            = var.public_ssh_key
  resource_group_name       = azurerm_resource_group.rg.name
  cluster_name              = var.cluster_name
  name_prefix               = var.name_prefix
  dcos_instance_os          = "centos_7.6"
  vm_size                   = "Standard_DS11_v2"
  disk_size                 = 128
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.test.id
}
