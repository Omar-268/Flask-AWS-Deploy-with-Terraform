# Flask-AWS-Deploy-with-Terraform

##📖 Description

This project demonstrates how to provision AWS infrastructure and deploy a simple Flask web application automatically using Terraform provisioners.

The infrastructure includes:

- A VPC with a public subnet.
- An Internet Gateway and Route Table for internet access.
- A Security Group allowing HTTP (80), HTTPS (443), Flask app port (5000), and SSH (22).
- An EC2 instance with Ubuntu.
- Terraform provisioners to:
  - Upload the Flask application (app.py + templates/).
  - Install Python3 & Flask.
  - Run the Flask app in the background.
