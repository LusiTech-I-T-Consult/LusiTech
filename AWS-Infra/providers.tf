provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

provider "aws" {
  region = var.dr_region
  alias  = "dr"
}
