

# `ECS Autoscaling with Terraform: Dynamic Container Scaling for Optimized Resource Utilization`

The project contains Terraform scripts to deploy a Medusa backend on AWS using ECS and RDS. The infrastructure includes VPC, subnets, security groups, ECS cluster, auto-scaling policies, and an RDS PostgreSQL database









## `Project Objectives`

`Dynamic Resource Management:`

 Automatically adjust the number of ECS tasks based on real-time CPU and memory usage to optimize resource allocation.

`Cost Efficiency:` 

Reduce operational costs during low-demand periods by minimizing the number of running tasks while ensuring that sufficient resources are available during peak traffic.

`Improved Performance:`

 Maintain high application performance and availability by quickly scaling out additional resources to handle increased workloads.

`Enhanced Reliability:`

 Ensure that the Medusa backend remains responsive and reliable, providing a seamless user experience even under varying load conditions.

`Scalability:`

 Facilitate the growth of the application by allowing it to handle increased traffic without manual intervention or downtime.
## 🔗 Links
[![linkedin](https://img.shields.io/badge/linkedin-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/sathish-gurka)


## Authors

- [@GurkaSathish](https://github.com/sathishyadav024)


## `Pre-Requisites`

- `AWS account (user)`

- `Linux`

- `Terraform`



## `Project Structure`
```
Devops-Internship-1.9/
├── main.tf           # Terraform configuration
├── variables.tf      # Variables for Terraform
├── terraform.tfvars  # Values for variables in variables.tf, used for environment settings.
├── README.md         # Project documentation
```
![Screenshot 2024-10-03 110929](https://github.com/user-attachments/assets/967cde4b-c51f-4e46-abb6-859fc7e51a3b)

![Screenshot 2024-10-03 111019](https://github.com/user-attachments/assets/82f156ab-8849-4b77-964c-e27415a35499)

## `Technologies Used`

`1. AWS Services:`

Amazon ECS (Elastic Container Service)

Amazon ECR (Elastic Container Registry)

Amazon VPC (Virtual Private Cloud)

`2. Infrastructure as Code:`

Terraform

`3. Containerization:`

Docker


## `Contact`


   For any inquiries or issues related to this project, please reach out via email:  
   
   
   Author: `Gurka Sathish`
   
   Email: ` sathishgurka@gmail.com `
## `Result`

The autoscaling implementation for the Medusa backend optimized resource usage, reduced costs, ensured consistent performance during traffic spikes, and allowed for seamless application growth without manual intervention. 
