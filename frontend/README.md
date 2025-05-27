# Frontend Documentation

This README provides instructions on how to build and run the frontend container for the Docker Compose project.

## Overview

The frontend of this project serves a simple "Hello World" webpage that displays the number of requests counted by the backend API.

## Building the Frontend

To build the frontend Docker image, navigate to the `frontend` directory and run the following command:

```
docker build -t frontend .
```

## Running the Frontend

To run the frontend container, you can use Docker Compose. From the root of the project directory, execute:

```
docker-compose up frontend
```

This will start the frontend service, which will be accessible at `http://localhost:80`.

## Accessing the Webpage

Once the frontend container is running, open your web browser and navigate to `http://localhost:80` to view the "Hello World" webpage. The page will display the message along with the number of requests counted by the backend API.