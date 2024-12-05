resource "aws_vpc" "my_vpc" {
  cidr_block = "72.25.227.0/24" 

  tags = {
    Name = "My-VPC1"
  }
}
resource "aws_subnet" "my_subnet" {
  vpc_id  = aws_vpc.my_vpc.id
  cidr_block = "72.25.227.0/26"  
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Public-Subnet"
  }   
}
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "72.25.227.64/26"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private-Subnet"
  }
}
resource "aws_internet_gateway" "my_igw"{
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "My-Internet-Gateway"
  }
}

resource "aws_route_table" "my_route" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }
    tags = {
    Name = "My-Internet-Gateway"
  }
}
resource "aws_route_table_association" "my_route_assc" {
  subnet_id = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route.id
}

#Elastic ip
resource "aws_eip" "nat_eip" {
  tags = {
    Name = "NAT-Gateway-EIP"  
  }
}

# NAT Gateway
resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.my_subnet.id

  tags = {
    Name = "My-NAT-Gateway"
  }
}
# Private Route Table
resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat_gateway.id
  }

  tags = {
    Name = "Private-Route-Table"
  }
}
resource "aws_security_group" "sg1" {
  vpc_id = aws_vpc.my_vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  ingress {
    from_port = 80
    to_port = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  ingress {
    from_port = 3000
    to_port = 3000
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "test" {
  ami = "ami-0dee22c13ea7a9a67"  
  instance_type = "t2.micro" 
  key_name  = "MyKeyPair" 
  subnet_id = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.sg1.id]
  associate_public_ip_address = true

  tags = {
    Name = "TestInstance1"
  }
}

resource "aws_instance" "test2" {
  ami = "ami-0dee22c13ea7a9a67"  
  instance_type = "t2.micro" 
  key_name  = "MyKeyPair" 
  subnet_id = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sg1.id]

  tags = {
    Name = "TestInstance2"
  }
  }

resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-test-bucketshivamj232323"
  tags = {
    Name        = "Test Public Bucket"
  }
}
resource "aws_s3_bucket_public_access_block" "my_bucket_block" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.my_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.my_bucket.arn}/*"
      }
    ]
  })
}