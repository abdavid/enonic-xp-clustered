module "enonic-xp" {
  source = "../modules/enonic"

  environment         = "prod"
  enonic_ami          = "ami-006fdf54c9b918959"
  enonic_docker_image = "enonic/xp:7.7.1-ubuntu"
  enabled_azs         = ["eu-central-1a"]
  hosted_zone_id      = "Z060486124RWXT9IBFS7Z"

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
