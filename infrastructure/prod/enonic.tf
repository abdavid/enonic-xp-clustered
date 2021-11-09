variable "docker_dir" {
  type = string
}
module "enonic-xp" {
  source = "../modules/enonic"

  environment    = "prod"
  enonic_ami     = "ami-006fdf54c9b918959"
  docker_dir     = var.docker_dir
  enabled_azs    = ["eu-central-1a"]
  hosted_zone_id = "Z060486124RWXT9IBFS7Z"

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