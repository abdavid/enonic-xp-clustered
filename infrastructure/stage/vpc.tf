module "vpc" {
  source   = "../modules/vpc"
  network  = "10.88.85.128/25"
  private  = false
  vpc_name = "enonic-pre"
}
