# website URL
output "website_url" {
    value = join("", ["https://", var.record_name, ".", var.domain_name])
}

# VPC id
output "vpc_id" {
    value = aws_vpc.vpc.id
}
    
