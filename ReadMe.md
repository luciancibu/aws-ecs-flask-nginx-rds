# AWS ECS + ALB + RDS Demo Project

This project demonstrates a AWS architecture using:

-   **ECS Fargate**
-   **Application Load Balancer (ALB)**
-   **RDS MySQL**
-   **ECR**
-   **Terraform**
-   **GitHub Actions (CI/CD)**

The application consists of: - **Frontend**: Nginx serving static
HTML/CSS - **Backend**: Flask application that stores and reads a page
view counter from MySQL

------------------------------------------------------------------------

## Architecture

    Internet
      |
      v
    Application Load Balancer (public)
      |
      |-- /          -> Frontend ECS Service (Nginx)
      |-- /view      -> Backend ECS Service (Flask)
                          |
                          v
                      RDS MySQL (private)

------------------------------------------------------------------------

## Repository Structure

    .
    ├── backend/
    │   ├── app.py
    │   ├── requirements.txt
    │   └── Dockerfile
    │
    ├── frontend/
    │   ├── index.html
    │   ├── style.css
    │   ├── default.conf
    │   └── Dockerfile
    │
    ├── infra/
    │   ├── providers.tf
    │   ├── envs/
    │   │   └── dev/
    │   │       ├── main.tf
    │   │       ├── variables.tf
    │   │       └── terraform.tfvars
    │   └── modules/
    │       ├── vpc/
    │       ├── alb/
    │       ├── ecs/
    │       ├── rds/
    │       └── ecr/
    │
    └── .github/
        └── workflows/
            ├── backend.yml
            └── frontend.yml

------------------------------------------------------------------------

## How It Works

### Frontend

-   Served by Nginx on ECS
-   Static HTML + CSS
-   Calls backend using `fetch("/view")`

### Backend

-   Flask app running on ECS
-   Exposes `/view` endpoint
-   Connects to RDS using environment variables:
    -   `DB_HOST`
    -   `DB_PORT`
    -   `DB_USER`
    -   `DB_PASSWORD`
    -   `DB_NAME`

### Database

-   MySQL (RDS)
-   Table `counter` stores a single row with view count

------------------------------------------------------------------------

## CI / CD

GitHub Actions pipelines: - Build Docker images - Push images to ECR -
Force ECS redeploy

### Triggers

-   Automatic on push to `frontend/` or `backend/`
-   Manual using `workflow_dispatch`

------------------------------------------------------------------------

## Deployment Steps

1.  Configure AWS credentials (IAM user)

2.  Deploy infrastructure:

    ``` bash
    terraform init
    terraform apply
    ```

3.  Push code:

    ``` bash
    git push
    ```

4.  Access application:

        http://<ALB_DNS>/
        http://<ALB_DNS>/view

------------------------------------------------------------------------

## Important Notes

-   ECS services run in **private subnets**
-   Only the **ALB is public**
-   ALB performs **path-based routing**
-   CloudWatch log groups must exist for ECS logging

------------------------------------------------------------------------