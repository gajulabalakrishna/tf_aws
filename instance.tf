resource "aws_instance" "app_server" {
  ami           = "ami-00c257e12d6828491"
  instance_type = "t3.micro"
  count = 1

  tags = {
    Name = "ExampleAppServerInstance"
  }
}
