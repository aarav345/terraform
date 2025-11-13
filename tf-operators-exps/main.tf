terraform {}


variable "num_list" {
    type = list(number)
    default = [ 1,2,3,4,5 ]
}

variable "person_list" {
    type = list(object({
        fname = string
        lname = string 
    }))

    default = [ {
        fname = "Aarav"
        lname = "Gupta"
    },
    {
        fname = "Riya"
        lname = "Gupta"
    } ]
}


variable "map_list" {
    type = map(number)
    default = {
        "one" = 1
        "two" = 2
    }
}


locals {
    mul = 2 * 5
    eq = 2 != 3

    double = [for num in var.num_list: num * 2]
    odd = [for num in var.num_list: num if num % 2 != 0]
    fname = [for person in var.person_list: person.fname]
    map_info = [for key, value in var.map_list: "${key}: ${value}"]
    map_info2 = { for key, value in var.map_list: key => value * 2} # creates a secondary map

}


output "arithmetic" {
    value = local.map_info2
}