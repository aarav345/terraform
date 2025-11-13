terraform {
  
}


locals {
  value = "Hello world"
}


variable "string_list" {
    type = list(string)
    default = [ "sev1", "sev2", "sev3" ]
}


output "name" {
    # value = lower(local.value)
    # value = startswith(local.value, "Hello")
    # value = split(" ", local.value)
    # value = max(1,2,3,45,5,6)
    # value = abs(-15)
    # value = length(var.string_list)
    # value = join(":", var.string_list)
    # value = contains(var.string_list, "sev21")
    value = toset(var.string_list)
}