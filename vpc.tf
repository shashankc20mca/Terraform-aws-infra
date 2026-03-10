#Creating the vpc
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

#creating the public-subnet-1
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"           = "1"
  }

}

#Creating the public-subnet-2
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"           = "1"
  }

}

#Creating the private-subnet-1
resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"


tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

}

#Creating the private-subnet-2
resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"

tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

}

#Creating the internet-gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}


#creating the elastic ip
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

#creating the Nat-Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.sub1.id   # Public subnet

  depends_on = [aws_internet_gateway.igw]
}



#creating the public-route-table
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

#Creating the private-route-table
resource "aws_route_table" "privateRT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}


#creating public-route-table associations
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

#creating public-route-table associations
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT.id
}

#creating private-route-table associations
resource "aws_route_table_association" "private_rta1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.privateRT.id
}


#creating private-route-table associations
resource "aws_route_table_association" "private_rta2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.privateRT.id
}

#creating the bastion-security-group
resource "aws_security_group" "bastionSg" {
  name   = "bastion"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "SSH FROM BASTION IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
/*
#ALB security group (public HTTP/HTTPS in)
/*resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
 /* vpc_id = aws_vpc.myvpc.id

  /*ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Optional (only if you will terminate TLS on ALB)
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
   /* to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  /*egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}*/
/*

#Creating the public-ec2-security_group
/*resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

   # Only ALB can talk to web instances on port 80
  /*ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "SSH FROM BASTION"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastionSg.id] #ALLOW SSH FROM BASTON HOST SG ONLY
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  /*  cidr_blocks = ["0.0.0.0/0"]
  }
/*
  tags = {
    Name = "Web-sg"
  }
}
*/
#Creating the private-ec2-security_group
resource "aws_security_group" "privateSg" {
  name   = "private-ec2"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description     = "SSH FROM BASTION"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastionSg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#EKS cluster sg
resource "aws_security_group" "eks_cluster_sg" {
  name        = var.eks_sg
  description = "Allow 443 from Jump Server only"

  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr] // It should allow from only baston sg to access eks cluster 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.eks_sg
  }
}



/*
#creating the public-instance-1
/*resource "aws_instance" "webserver1" {
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub1.id
  user_data_base64       = base64encode(file("userdata.sh"))
/*  key_name = var.key

}
*/
/*
#creating the public-instance-2
/*resource "aws_instance" "webserver2" {
 /* ami                    = var.ami
  /*instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub2.id
  user_data_base64       = base64encode(file("userdata1.sh"))
/*  key_name = var.key

}*/



#Creating the bastion-instance
resource "aws_instance" "bastion" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.sub1.id
  vpc_security_group_ids = [aws_security_group.bastionSg.id]
  key_name = var.key
  #associate_public_ip_address = true #no need to add here we have already specified in subnet sub1
}

#creating the private-instance-1
resource "aws_instance" "private1" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.privateSg.id]
  key_name = var.key
}

#creating the private-instance-2
resource "aws_instance" "private2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private2.id
  vpc_security_group_ids = [aws_security_group.privateSg.id]
  key_name = var.key
}



/*
#create alb
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]
  subnets         = [aws_subnet.sub1.id, aws_subnet.sub2.id] #attaching the public-subnets to it

  tags = {
    Name = "web"
  }
}
/*
#creating load-balancer-target-group
resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id
/*
  health_check {
    path = "/"
    port = "traffic-port"
  }
} 
/*
#attaching the public-instance1 to target-group
/*resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  /*target_id        = aws_instance.webserver1.id
  port             = 80
}
/*
#attaching the public-instance2 to target-group
/* resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}
/*
#creating listner port for lb
/*resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  /* default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

/*
#getting the output of the loadbalancer dns name created
 /* output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}





#creating s3_bucket
/* resource "aws_s3_bucket" "example" {
  bucket = "abhisheksterraform2023project"
}
*/
