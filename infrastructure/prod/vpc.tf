module "vpc" {
  source   = "../modules/vpc"
  network  = "10.88.84.0/25"
  private  = false
  vpc_name = "enonic-pro"
}
