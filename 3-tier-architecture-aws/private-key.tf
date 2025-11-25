resource "tls_private_key" "keyPair" {
    algorithm = "RSA"
    rsa_bits = 4096
}


resource "aws_key_pair" "terraform_key" {
    key_name = "${var.project_name}-key"
    public_key = tls_private_key.keyPair.public_key_openssh
}


resource "local_file" "private_key_pem" {
    content  = tls_private_key.keyPair.private_key_pem
    filename = "${path.module}/${var.project_name}-key.pem"
}