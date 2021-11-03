variable "hosted_zone_id" {
  type = string
}

data "aws_route53_zone" "zone" {
  zone_id = var.hosted_zone_id
}

resource "aws_route53_record" "enonic" {
  zone_id = data.aws_route53_zone.zone.id
  name    = "enonic.${data.aws_route53_zone.zone.name}"
  type    = "A"
  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "enonic" {
  domain_name       = "enonic.${data.aws_route53_zone.zone.name}"
  validation_method = "DNS"
}

resource "aws_route53_record" "enonic_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.enonic.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "enonic" {
  certificate_arn         = aws_acm_certificate.enonic.arn
  validation_record_fqdns = [for record in aws_route53_record.enonic_cert_validation : record.fqdn]
}
