resource "aws_vpc" "sl_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "sl-vpc"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.sl_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  depends_on = [aws_vpc.sl_vpc]
  tags = {
    Name = "sl-subnet"
  }
}

resource "aws_route_table" "sl_route_table" {
  vpc_id = aws_vpc.sl_vpc.id
  tags = {
    Name = "sl-route-table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.sl_route_table.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.sl_vpc.id
  depends_on = [aws_vpc.sl_vpc]
  tags = {
    Name = "sl-gw"
  }
}

resource "aws_route" "sl_route" {
  route_table_id         = aws_route_table.sl_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_security_group" "project_securitygroup" {
  name        = "project-securitygroup"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = aws_vpc.sl_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project-securitygroup"
  }
}

resource "tls_private_key" "web_key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "app_key" {
  key_name   = "web-key"
  public_key = tls_private_key.web_key.public_key_openssh
}

resource "local_file" "web_key" {
  content  = tls_private_key.web_key.private_key_pem
  filename = "web-key.pem"

  provisioner "local-exec" {
    command = "chmod 600 ${self.filename}"
  }

}

resource "aws_instance" "kubernetes_master" {
  ami             = "ami-04b70fa74e45c3917"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.subnet_1.id
  key_name        = "web-key"
  security_groups = [aws_security_group.project_securitygroup.id]
  tags = {
    Name = "Kubernetes-Master"
  }

  provisioner "remote-exec" {
      inline = [ "echo 'wait to start instance' "]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.web_key.private_key_pem
    host        = self.public_ip
  }
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_master.public_ip} > inventory "
  }
   provisioner "local-exec" {
  	command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/k8s-master-setup.yml"
  }
  
}

resource "aws_instance" "kubernetes_worker_1" {
  ami             = "ami-04b70fa74e45c3917"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.subnet_1.id
  key_name        = "web-key"
  security_groups = [aws_security_group.project_securitygroup.id]
  tags = {
    Name = "Kubernetes-Worker-1"
  }

  provisioner "remote-exec" {
      inline = [ "echo 'wait to start instance' "]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.web_key.private_key_pem
    host        = self.public_ip
  }
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_worker_1.public_ip} > inventory "
  }
   provisioner "local-exec" {
       command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/k8s-worker-setup.yml "
  }
  depends_on = [aws_instance.kubernetes_master]
}

resource "aws_instance" "kubernetes_worker_2" {
  ami             = "ami-04b70fa74e45c3917"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.subnet_1.id
  key_name        = "web-key"
  security_groups = [aws_security_group.project_securitygroup.id]
  tags = {
    Name = "Kubernetes-Worker-2"
  }

  provisioner "remote-exec" {
      inline = [ "echo 'wait to start instance' "]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.web_key.private_key_pem
    host        = self.public_ip
  }
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_worker_2.public_ip} > inventory "
  }
   provisioner "local-exec" {
       command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/k8s-worker-setup.yml "
  }
  depends_on = [aws_instance.kubernetes_worker_1]
}

resource "null_resource" "local_command" {
  
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_master.public_ip} > inventory "
  }
   
   provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/monitring-deployment.yml"
  }

   provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/deployservice.yml"
  }
  depends_on = [aws_instance.kubernetes_worker_2]

}

resource "null_resource" "local_command" {
  
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_worker_1.public_ip} > inventory "
  }
   
   provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/monitring-deployment.yml"
  }

   provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/deployservice.yml"
  }
  depends_on = [null_resource.local_command]

}

resource "null_resource" "local_command" {
  
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_worker_2.public_ip} > inventory "
  }
   
   provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/monitring-deployment.yml"
  }

   provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/deployservice.yml"
  }
  depends_on = [aws_instance.kubernetes_worker_2]

}


resource "aws_instance" "monitoring_server" {
  ami             = "ami-04b70fa74e45c3917"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.subnet_1.id
  key_name        = "web-key"
  security_groups = [aws_security_group.project_securitygroup.id]
  tags = {
    Name = "Monitoring-Server"
  }

  provisioner "remote-exec" {
      inline = [ "echo 'wait to start instance' "]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.web_key.private_key_pem
    host        = self.public_ip
  }
   provisioner "local-exec" {
        command = " echo ${aws_instance.monitoring_server.public_ip} > inventory "
  }
   provisioner "local-exec" {
  command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/monitring.yml "
  }
depends_on = [null_resource.local_command]
  
 
  
}
