# Jenkins CI/CD Delivery Project

## Author
Oluwatoba Lojede

## Project Overview
This project demonstrates a complete CI/CD workflow using GitHub, Jenkins, Docker, Docker Hub, Terraform, and Microsoft Azure.

A code change pushed to GitHub automatically triggers Jenkins. Jenkins builds the Python application into a Docker image, logs in to Docker Hub using stored credentials, and pushes the completed image to a private Docker Hub repository.

## Technologies Used
- Python
- GitHub
- Jenkins
- Docker
- Docker Hub
- Terraform
- Microsoft Azure

## Project Files
- `Oluwatoba.Lojede.py` - Simple Python application
- `Dockerfile` - Builds the Docker image
- `Jenkinsfile` - Defines the CI/CD pipeline
- `main.tf` - Creates the Azure infrastructure
- `README.md` - Project documentation

## Prerequisites
Before running this project, you need:
- Git
- Terraform
- Azure CLI
- GitHub account
- Docker Hub account
- Jenkins server
- Azure subscription

## Python Application
Run the Python application locally with:

```bash
python3 Oluwatoba.Lojede.py