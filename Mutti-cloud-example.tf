# Provider configuration for AWS
provider "aws" {
  access_key = "YOUR_AWS_ACCESS_KEY"
  secret_key = "YOUR_AWS_SECRET_KEY"
  region     = "us-west-2"
}

# Provision an EC2 instance on AWS
resource "aws_instance" "example" {
  ami           = "ami-0c94855ba95c71c99"  # Replace with the desired AMI ID
  instance_type = "t2.micro"
  key_name      = "my-keypair"

  tags = {
    Name = "Example Instance"
  }
}

# Provider configuration for GCP
provider "google" {
  credentials = file("path/to/gcp_credentials.json")
  project     = "your-project-id"
  region      = "us-central1"
}

# Provision a Compute Engine instance on GCP
resource "google_compute_instance" "example" {
  name         = "example-instance"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"  # Replace with the desired image
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral IP
    }
  }

  tags = ["example"]
}

# Provider configuration for Azure
provider "azurerm" {
  features {}
}

# Provision a virtual machine on Azure
resource "azurerm_virtual_machine" "example" {
  name                  = "example-vm"
  location              = "eastus"
  resource_group_name   = "example-resource-group"
 
