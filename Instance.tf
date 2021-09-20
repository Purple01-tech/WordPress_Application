#create vpc and specify cidr block

resource "aws_vpc" "Motivalogic_VPC" {
cidr_block = "10.0.0.0/16"
tags = {
Name = "Motivalogic_VPC"
}
}

# Creating 2  subnets 1 public and 1 private 
resource "aws_subnet" "Motivalogic_Pub_SN" {
  vpc_id     = aws_vpc.Motivalogic_VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "Motivalogic_Pub_SN"
  }
}

resource "aws_subnet" "Motivalogic_Prv_SN" {
  vpc_id     = aws_vpc.Motivalogic_VPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "Motivalogic_Prv_SN"
  }
}

resource "aws_subnet" "Motivalogic_BKP_SN" {
  vpc_id     = aws_vpc.Motivalogic_VPC.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "eu-west-2c"

  tags = {
    Name = "Motivalogic_BKP_SN"
  }
}


#Create frontEnd Security Group and BackEnd Security Group
resource "aws_security_group" "Motivalogic_FrontEnd_SG" {
    description = "Allow TLS inbound traffic"
    vpc_id      = aws_vpc.Motivalogic_VPC.id

    ingress {
    description = "http rule"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "https rule"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh rule"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Motivalogic_FrontEnd_SG"
  }
}

resource "aws_security_group" "Motivalogic_BackEnd_SG" {
    description = "Allow SSH and Mysql inbound traffic"
    vpc_id      = aws_vpc.Motivalogic_VPC.id
  ingress {
    description = "mysql rule"
    from_port   = 43
    to_port     = 43
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    description = "ssh rule"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  tags = {
    Name = "Motivalogic_BackEnd_SG"
  }
}

# creating internet gateway for the network 
resource "aws_internet_gateway" "Motivalogic_VPC_IGW" {
  vpc_id = aws_vpc.Motivalogic_VPC.id

  tags = {
    Name = "Motivalogic_VPC_IGW"
  }
}

# For EIP
resource "aws_eip" "Motivalogic_eip" {
  vpc      = true
}

# Output for the EIP
output "public_ip" {
  description = "Contains the public IP address"
  value       = aws_eip.Motivalogic_eip.public_ip
}

# Creating the NAT gateway
resource "aws_nat_gateway" "Motivalogic_VPC_NG" {
  allocation_id = aws_eip.Motivalogic_eip.id
  subnet_id     = aws_subnet.Motivalogic_Pub_SN.id
}

# Creating the Route tables
resource "aws_route_table" "Motivalogic_VPC_RT_Pub_SN" {
  vpc_id = aws_vpc.Motivalogic_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Motivalogic_VPC_IGW.id
  }
}

resource "aws_route_table" "Motivalogic_VPC_RT_Prv_SN" {
  vpc_id = aws_vpc.Motivalogic_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Motivalogic_VPC_IGW.id
  }
}


#Route table Association
resource "aws_route_table_association" "Motivalogic_VPC_RT_Prv_SN" {
  subnet_id      = aws_subnet.Motivalogic_Prv_SN.id
  route_table_id = aws_route_table.Motivalogic_VPC_RT_Prv_SN.id
}

resource "aws_route_table_association" "Motivalogic_VPC_PubRT_PubSN" {
  subnet_id      = aws_subnet.Motivalogic_Pub_SN.id
  route_table_id = aws_route_table.Motivalogic_VPC_RT_Pub_SN.id
}

resource "aws_route_table_association" "Motivalogic_VPC_PrvRT_Prv_BKP_SN" {
  subnet_id      = aws_subnet.Motivalogic_BKP_SN.id
  route_table_id = aws_route_table.Motivalogic_VPC_RT_Pub_SN.id
}

##############################################################################

# Creation of S3 public and private buckets  and the policy for the Mini project
resource "aws_s3_bucket" "Motivalogic" {
  bucket = "motivateam4media"
  acl    = "public-read"

}


resource "aws_s3_bucket" "Motivalogic_bkp" {
  bucket = "motivateam4bkp"
  acl    = "private"
}


resource "aws_s3_bucket_policy" "Motivalogic" {
  bucket = "motivateam4media"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "Motivalogic_policy",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
    "Principal": "*",
      "Action": [
          "s3:GetObject"
          ],
      "Resource":[
          "arn:aws:s3:::motivateam4media/*"
      ]
    }
  ]
}
POLICY
}
#create RDS database for the back-end
resource "aws_db_instance" "motivalogicdbinstance" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0.17"
  instance_class       = "db.t2.micro"
  name                 = "motivalogicdb"
  username             = "cloudhightadmin"
  password             = "Motiva123Logic!"
  #vpc_id      =  aws_vpc.Motivalogic_VPC.id
  #vpc_security_group_ids = ["${aws_security_group.Motivalogic_BackEnd_SG.id}"]
  #subnet_id      = aws_subnet.Motivalogic_Prv_SN.id
  db_subnet_group_name      = "${aws_db_subnet_group.motivalogicdb_subnet_group.id}"
  vpc_security_group_ids = ["${aws_security_group.Motivalogic_BackEnd_SG.id}"]
  skip_final_snapshot       = true
  final_snapshot_identifier = "Ignore"
}

resource "aws_db_subnet_group" "motivalogicdb_subnet_group" {
  name        = "motivalogicdb_subnet_group"
  description = "database private groups"
  subnet_ids  = ["${aws_subnet.Motivalogic_Prv_SN.id}","${aws_subnet.Motivalogic_BKP_SN.id}"]
}

##############################################################################################################
resource "aws_s3_bucket" "s3bucket" {
  bucket = "motivateam4media"
  acl    = "private"

  tags = {
    Name = "s3bucket"
  }
}

locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.s3bucket.bucket_regional_domain_name
    origin_id = local.s3_origin_id
  }
  
  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket = "motivateam4media.s3.amazonaws.com"
    

  }

  default_cache_behavior {
    allowed_methods = [
      "DELETE",
      "GET",
      "HEAD",
      "OPTIONS",
      "PATCH",
      "POST",
      "PUT"]
    cached_methods = [
      "GET",
      "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern = "/*"
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"]
    cached_methods = [
      "GET",
      "HEAD",
      "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers = [
        "Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl = 0
    default_ttl = 86400
    max_ttl = 31536000
    compress = true
    viewer_protocol_policy = "redirect-to-https"
  }

//  # Cache behavior with precedence 1
//  ordered_cache_behavior {
//    path_pattern = "/content/*"
//    allowed_methods = [
//      "GET",
//      "HEAD",
//      "OPTIONS"]
//    cached_methods = [
//      "GET",
//      "HEAD"]
//    target_origin_id = local.s3_origin_id
//
//    forwarded_values {
//      query_string = false
//
//      cookies {
//        forward = "none"
//      }
//    }
//
//    min_ttl = 0
//    default_ttl = 3600
//    max_ttl = 86400
//    compress = true
//    viewer_protocol_policy = "redirect-to-https"
//  }



  restrictions {
    geo_restriction {
      restriction_type = "none"

    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
  
    cloudfront_default_certificate = true
    
  }
}


#############################################################
  # create key-pair
resource "aws_key_pair" "keypair" {
  key_name   = "keypair"
  public_key = file("C:/Users/DevOpstraining/keypair.pub")
}

#################################################################
# Create EC2 Instance attached key pair, attached to public subnet, attached to front end security group

#create ec2-instance, attach key-pair, attach to public-subnet, attach to front-end security group
#specify the connection type

resource "aws_instance" "Web_app_server1" {
key_name      = aws_key_pair.keypair.key_name
        subnet_id      = aws_subnet.Motivalogic_Pub_SN.id
ami = "ami-0fc841be1f929d7d1"
user_data              = file("wordpress.sh")
instance_type = "t2.micro"
vpc_security_group_ids = ["${aws_security_group.Motivalogic_FrontEnd_SG.id}"]
connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/Users/DevOpstraining/keypair")
    host        = self.public_ip
  }


 }