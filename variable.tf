# variable "gcp_project_id" {
#     type = string
# }

variable "gcp_region" {
    type = string
}


variable "billing"{
    type = string
}

variable "envs"{
    type = list(map(string))
}