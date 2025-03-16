provider "aws" {
  region = "us-east-1" # Change to your preferred region
}

resource "aws_instance" "vm" {
  ami           = "ami-00c257e12d6828491" # Ubuntu AMI (update as needed)
  instance_type = "t3.micro"

  tags = {
    Name = "GitHubActions-VM"
  }
}

output "instance_ip" {
  description = "Public IP of the created EC2 instance"
  value       = aws_instance.vm.public_ip
}
