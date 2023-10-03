provider "aws" {
  region     = "ca-central-1"
  access_key = ""
  secret_key = ""
}


# Create VPC
# terraform aws create vpc

resource "aws_vpc" "vpc" {
    cidr_block = "${var.vpc-cidr}"
    instance_tenancy        = "default"
    #enable_dns_hostnames    = true

    tags = {
      Name = "${var.vpc-tag}"
     }
}

# Create TGW Private Subnet in ca-central-1d
# terraform aws create subnet
resource "aws_subnet" "tgw_subnet" {
  for_each = toset(var.availability_zones)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.tgw_subnet[index(var.availability_zones, each.value)]
  availability_zone = each.value
}

# Create Private Subnet in ca-central-1d
# terraform aws create subnet
resource "aws_subnet" "data_subnet" {
  for_each = toset(var.availability_zones)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.data_subnet[index(var.availability_zones, each.value)]
  availability_zone = each.value
}

# create transit gateway attachment
# terraform aws create transit gateway attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_attachment" {
    vpc_id  = aws_vpc.vpc.id
    subnet_ids  =  values(aws_subnet.tgw_subnet)[*].id
    transit_gateway_id = "tgw-"
    #dns_support = enable

    tags = {
        Name = "${var.transit_gateway_attachment}"
    }
}

# Create Route Table and Add routes 
# terraform aws create route table
resource "aws_route_table" "private_subnet_rt" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        transit_gateway_id = "tgw-"
    }
    tags = {
        Name = "private_subnet_rt"
    }
}

