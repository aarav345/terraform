# AWS VPC Terraform Module

A flexible Terraform module for creating AWS VPC infrastructure with configurable public and private subnets, automatic Internet Gateway setup, and intelligent routing.

## Features

- Creates a VPC with custom CIDR block
- Supports multiple public and private subnets across different availability zones
- Automatically provisions Internet Gateway for public subnets
- Configures route tables and associations for public subnet internet access
- Built-in CIDR block validation
- Flexible subnet configuration with optional public/private designation

## Requirements

- Terraform >= 1.0
- AWS Provider >= 6.21.0

## Usage

```hcl
provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source = "./module/vpc"
  
  vpc_config = {
    cidr_block = "10.0.0.0/16"
    name       = "my-test-vpc"
  }
  
  subnet_config = {
    public_subnet-1 = {
      cidr_block = "10.0.4.0/24"
      az         = "ap-south-1a"
      public     = true
    }
    public_subnet-2 = {
      cidr_block = "10.0.5.0/24"
      az         = "ap-south-1b"
      public     = true
    }
    private_subnet = {
      cidr_block = "10.0.6.0/24"
      az         = "ap-south-1b"
      # public defaults to false
    }
  }
}
```

## Input Variables

### vpc_config

Configuration object for the VPC.

- **Type**: `object`
- **Required**: Yes
- **Attributes**:
  - `cidr_block` (string): The CIDR block for the VPC (e.g., "10.0.0.0/16")
  - `name` (string): Name tag for the VPC

### subnet_config

Map of subnet configurations. Each key becomes the subnet name.

- **Type**: `map(object)`
- **Required**: Yes
- **Object Attributes**:
  - `cidr_block` (string): CIDR block for the subnet
  - `az` (string): Availability zone for the subnet
  - `public` (bool): Whether the subnet is public (defaults to false)

## Outputs

### vpc_id

The ID of the created VPC.

```hcl
output "vpc" {
  value = module.vpc.vpc_id
}
```

### public_subnets

Map of public subnet information with subnet IDs and availability zones.

```hcl
output "public_subnets" {
  value = module.vpc.public_subnets
}
```

**Output format**:
```hcl
{
  "public_subnet-1" = {
    subnet_id = "subnet-xxxxx"
    az        = "ap-south-1a"
  }
}
```

### private_subnets

Map of private subnet information with subnet IDs and availability zones.

```hcl
output "private_subnets" {
  value = module.vpc.private_subnets
}
```

**Output format**:
```hcl
{
  "private_subnet" = {
    subnet_id = "subnet-xxxxx"
    az        = "ap-south-1b"
  }
}
```

## Module Behavior

### Public Subnets

Subnets marked with `public = true` will:
- Be associated with a route table that routes internet traffic (0.0.0.0/0) through an Internet Gateway
- Have internet connectivity for resources with public IPs

### Private Subnets

Subnets marked with `public = false` (or omitting the public attribute):
- Will not have direct internet access
- Suitable for backend services and databases

### Conditional Resources

- **Internet Gateway**: Only created if at least one public subnet exists
- **Route Table**: Only created if at least one public subnet exists
- **Route Table Associations**: Only created for public subnets

## Validation

The module includes built-in validation:
- VPC CIDR block must be in valid CIDR format
- All subnet CIDR blocks must be in valid CIDR format

## Example with Multiple Subnets

```hcl
module "vpc" {
  source = "./module/vpc"
  
  vpc_config = {
    cidr_block = "10.0.0.0/16"
    name       = "production-vpc"
  }
  
  subnet_config = {
    public-web-1 = {
      cidr_block = "10.0.1.0/24"
      az         = "us-east-1a"
      public     = true
    }
    public-web-2 = {
      cidr_block = "10.0.2.0/24"
      az         = "us-east-1b"
      public     = true
    }
    private-app-1 = {
      cidr_block = "10.0.10.0/24"
      az         = "us-east-1a"
    }
    private-app-2 = {
      cidr_block = "10.0.11.0/24"
      az         = "us-east-1b"
    }
    private-db-1 = {
      cidr_block = "10.0.20.0/24"
      az         = "us-east-1a"
    }
    private-db-2 = {
      cidr_block = "10.0.21.0/24"
      az         = "us-east-1b"
    }
  }
}
```

## Notes

- Ensure subnet CIDR blocks fall within the VPC CIDR range
- Choose availability zones available in your AWS region
- Public subnets require an Internet Gateway, which the module creates automatically
- For private subnet internet access (via NAT Gateway), you'll need to extend this module

## License

This module is available under your organization's standard license terms.