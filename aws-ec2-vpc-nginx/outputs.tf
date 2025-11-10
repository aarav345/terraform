output "instance_public_ip" {
    description = "The public ip address of EC2 instance"
    value = aws_instance.nginxserver.public_ip
}


output "instance_url" {
    description = "The URL to nginx server"
    value = "http://${aws_instance.nginxserver.public_ip}"
}