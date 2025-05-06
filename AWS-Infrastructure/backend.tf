terraform {
  backend "s3" {
    bucket       = "terra-state-1234"
    key          = "terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
