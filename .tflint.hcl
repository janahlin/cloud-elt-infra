plugin "aws" {
  enabled = true
  version = "0.30.0"
}

plugin "azurerm" {
  enabled = true
  version = "0.25.1"
}

plugin "google" {
  enabled = true
  version = "0.25.0"
}

plugin "oci" {
  enabled = true
  version = "0.10.0"
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_lookup" {
  enabled = true
}

rule "terraform_deprecated_splat" {
  enabled = true
}

rule "terraform_empty_list_equality" {
  enabled = true
}

rule "terraform_map_duplicate_keys" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_unused_required_providers" {
  enabled = true
}

rule "terraform_workspaces" {
  enabled = true
}
