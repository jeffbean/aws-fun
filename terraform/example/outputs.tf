output "address" {
  value = "${aws_instance.example.public_ip}"
}
