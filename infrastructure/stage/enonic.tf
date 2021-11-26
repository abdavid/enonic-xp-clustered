variable "enonic_docker_image" {
  type = string
}
variable "commit" {
  type = string
}
module "enonic-xp" {
  source = "../modules/enonic"

  environment         = "stage"
  enonic_docker_image = var.enonic_docker_image
  enabled_azs         = ["eu-central-1a"]
  hosted_zone_id      = "Z05981652ZPOCEC46HA9D"

  info_commit = var.commit

  instances = {
    zone-a = module.vpc.subnet_public0
  }
  vpc_id = module.vpc.vpc_id
  lb_subnets = [
    module.vpc.subnet_public0,
    module.vpc.subnet_public1,
    module.vpc.subnet_public2,
  ]
  enonic_repo = {
    name       = "enonic-xp",
    account_id = "953355806585",
    region     = "eu-central-1",
  }
}

output "apps_bucket" {
  value = module.enonic-xp.apps_bucket
}