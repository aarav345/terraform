module "ec2-instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.1.4"


  ami = "ami-02b8269d5e85954ef"
  instance_type = "t3.micro"
  vpc_security_group_ids = [ module.vpc.default_security_group_id ]
  subnet_id     = module.vpc.public_subnets[0]

  tags = {
    Name = "my-ec2-instance"
    Environment = "dev"
  }


}