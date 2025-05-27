# Backend Service

This directory contains the backend service for the Docker Compose project. The backend is built using Flask and is responsible for counting the number of requests made to it.

## Getting Started

To build and run the backend service, follow these steps:

1. **Build the Docker Image**:
   Navigate to the `backend` directory and run the following command:
   ```
   docker build -t backend .
   ```

2. **Run the Docker Container**:
   After building the image, you can run the container using:
   ```
   docker run -p 5000:5000 backend
   ```

3. **Access the API**:
   The backend API will be available at `http://localhost:5000/count`. Each request to this endpoint will increment the request count.

## API Endpoints

- **GET /count**: Returns the total number of requests received by the backend.

## Dependencies

This backend service requires the following Python packages:
- Flask

Make sure to install the dependencies listed in `requirements.txt` before running the application. You can do this by running:
```
pip install -r requirements.txt
```

## Notes

- Ensure that the backend service is running before accessing the frontend.
- The frontend will display the number of requests counted by the backend.