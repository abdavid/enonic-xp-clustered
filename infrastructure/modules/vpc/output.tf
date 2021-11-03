output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_public0" {
  value = aws_subnet.public0.id
}

output "subnet_public1" {
  value = aws_subnet.public1.id
}

output "subnet_public2" {
  value = aws_subnet.public2.id
}