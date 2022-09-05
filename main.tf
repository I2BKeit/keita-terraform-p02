# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  
  
}
# 1-    Create a VPC
resource "aws_vpc" "keita-demo-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "keita-demo-vpc"
  }
}
# 2-    Create an internet gateway 
resource "aws_internet_gateway" "keita-gw" {
  vpc_id = aws_vpc.keita-demo-vpc.id

  tags = {
    Name = "keita-gw"
  }
}
# 3-    Create Route Table 
resource "aws_route_table" "keita-route-table" {
  vpc_id = aws_vpc.keita-demo-vpc.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.keita-gw.id
  }

  tags = {
    Name = "keita-route-table"
  }
}
# 4-    Create two public route table
resource "aws_subnet" "keita-public-subnet-A" {
  vpc_id = aws_vpc.keita-demo-vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    "Name" = "keita-public-subnet-A"
  }

}
resource "aws_subnet" "keita-public-subnet-B" {
  vpc_id = aws_vpc.keita-demo-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1a"
  tags = {
    "Name" = "keita-public-subnet-B"
  }

}
# 5-    Associate route to the public subnet 
resource "aws_route_table_association" "Keita-public-RT-A" {
  subnet_id      = aws_subnet.keita-public-subnet-A.id
  route_table_id = aws_route_table.keita-route-table.id
  
  
}
resource "aws_route_table_association" "Keita-public-RT-B" {
  subnet_id      = aws_subnet.keita-public-subnet-B.id
  route_table_id = aws_route_table.keita-route-table.id
  
  
}
# 6-    Security group which allows pport: 22, 80, 443
resource "aws_security_group" "keita-terraform-demo" {
  name        = "keita-terraform-demo"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.keita-demo-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      =["0.0.0.0/0"] // Anyone can access this 
    
  }
   ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      =["0.0.0.0/0"] // Anyone can access this 
    
  }
   ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      =["0.0.0.0/0"] // Anyone can access this 
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  tags = {
    Name = "keita-terraform-demo"
  }
}
# 7-    Network interface 
resource "aws_network_interface" "keita" {
  subnet_id       = aws_subnet.keita-public-subnet-A.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.keita-terraform-demo.id]

  
}
#8  Create an EIP

resource "aws_eip" "keita-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.keita.id
  associate_with_private_ip = "10.0.0.50"
  depends_on = [
    aws_internet_gateway.keita-gw
  ]
  
}
resource "aws_instance" "keita-demo-terraform-ec2" {
    ami ="ami-0cff7528ff583bf9a"
    instance_type ="t2.micro" 
    availability_zone = "us-east-1a"
    tags = {
      "Name" = "keita-demo-terraform-ec2"
        }
      key_name="done"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.keita.id
    
  }
 user_data = <<-EOF
 #!/bin/bash
yum update -y
yum -y install httpd
systemctl enable httpd
systemctl start httpd
echo '<html>
<body>

<h2>Thank you dear readers </h2>
<details>
   <summary>Terraform commands used </summary>
     <li>
      <ul>Terraform init</ul>
       <ul>Terraform plan</ul>
        <ul>Terraform apply</ul>
         <ul>Terraform destroy</ul>
     </li>
   </details>
<details>
   <summary>Git commands used:</summary>
    <li> 
     <ul>git init </ul>
      <ul>git push </ul>
      <ul>git add .</ul>
       <ul>git commit -m"your messages" </ul>
        <ul>git remote add origin url </ul>
         
    </li>
    </details>
<p>Ibrehima keita </p>
</body>
</html>' > /var/www/html/index.html
EOF
}
