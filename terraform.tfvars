##############################################
# Cluster & Region
##############################################
region            = "us-east-1"
cluster_name      = "test-cluster"
cluster_version   = "1.27"

##############################################
# Node Group
##############################################
node_desired_size = 1
node_max_size     = 1
node_min_size     = 1
node_instance_types = ["t3.micro"]

##############################################
# Public Subnet & AZs
##############################################
public_subnets = ["10.0.1.0/24"]
azs            = ["us-east-1a"]

##############################################
# MariaDB / MediaWiki
##############################################
db_root_password = "change-me-root"
db_name          = "mediawikidb"
db_user          = "mediawikiuser"
db_password      = "change-me-user"

##############################################
# Jump Box
##############################################
ssh_key_name = "my-aws-key"               # your existing AWS EC2 key pair
my_ip_cidr   = "203.0.113.25/32"         # replace with your actual public IP

##############################################
# Optional
##############################################
deploy_jump_box = true
