
# Objective
The objective of this repository is to act as a template for creating azure containerapp hosted multi-container applications with GitHub CI/CD. 

# Docker Compose Project

This project consists of a simple web application with a frontend that displays a "Hello World" message and a backend API that counts the number of requests made to it. The project is structured into two main components: the frontend and the backend, each running in its own Docker container.

## Project Structure

```
docker-compose-project
├── frontend
│   ├── Dockerfile          # Instructions to build the frontend Docker image
│   ├── src
│   │   └── index.html      # HTML file displaying the "Hello World" message
│   └── README.md           # Documentation for the frontend
├── backend
│   ├── Dockerfile          # Instructions to build the backend Docker image
│   ├── src
│   │   └── app.py          # Main application file for the backend API
│   ├── requirements.txt     # Python dependencies for the backend
│   └── README.md           # Documentation for the backend
├── docker-compose.yml      # Configuration for Docker Compose
└── README.md               # General documentation for the project
```

## Getting Started

To get started with this project, ensure you have Docker and Docker Compose installed on your machine. Follow the steps below to build and run the application:

1. Clone the repository or download the project files.
2. Navigate to the project directory:
   ```
   cd docker-compose-project
   ```
3. Build the Docker images and start the containers using Docker Compose:
   ```
   docker-compose up --build
   ```
4. Access the frontend application by opening your web browser and navigating to `http://localhost:80`.

## Frontend

The frontend is a simple HTML page that displays a message. It fetches the request count from the backend API and updates the displayed message accordingly.

## Backend

The backend is a Flask application that counts the number of requests it receives. Each time the frontend makes a request, the backend increments the count and returns the total.