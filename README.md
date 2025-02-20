# AWS VPC Peering Template

This Terraform configuration sets up vpc peering between two already existing vpc's 


---

## 📌 Prerequisites

Ensure you have the following installed and configured:

- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [AWS CLI](https://aws.amazon.com/cli/) with AWS SSO authentication configured
- AWS profiles set up for each account using `aws configure sso`

---

## 🚀 Deployment Steps

### 1️⃣ Clone the Repository

```sh
git clone https://github.com/Zack1667/AWS-VPC-Peering-Template.git
cd vpc-peering
```

### 2️⃣ Modify TF values to match your own 

```sh
There are lots of values to modify, ensure you update them all. 
```

### 3️⃣ Initialize Terraform 

```sh
terraform init
```

### 4️⃣ Plan the Deployment 

```sh
terraform plan
```

### 5️⃣ Apply the Configuration

```sh
terraform apply
```

### 🛑 Cleanup 

To destroy all resources created by Terraform:

```sh

terraform destroy -auto-approve

```

### 🤝 Contributing

Feel free to submit issues or pull requests to improve this project!

