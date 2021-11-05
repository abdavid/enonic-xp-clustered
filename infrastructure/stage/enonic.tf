module "enonic-xp" {
  source = "../modules/enonic"

  environment         = "stage"
  enonic_ami          = "ami-006fdf54c9b918959"
  enonic_docker_image = "enonic/xp:7.6.1-ubuntu"
  enabled_azs         = ["eu-central-1a"]
  hosted_zone_id      = "Z05981652ZPOCEC46HA9D"

  instances = {
    zone-a = module.vpc.subnet_public0
  }
  vpc_id = module.vpc.vpc_id
  lb_subnets = [
    module.vpc.subnet_public0,
    module.vpc.subnet_public1,
    module.vpc.subnet_public2,
  ]
}

output "apps_bucket" {
  value = module.enonic-xp.apps_bucket
}