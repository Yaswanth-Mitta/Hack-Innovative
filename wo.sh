#!/bin/bash

# Create the k8s directory if it doesn't exist
mkdir -p k8s

# Create the .github/workflows directory if it doesn't exist
mkdir -p .github/workflows

# Create updated Kubernetes backend-deployment.yaml
cat << 'EOF' > k8s/backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: ${{ secrets.DOCKER_USERNAME }}/hack-innovate-backend:latest
          ports:
            - containerPort: 5000
          env:
            - name: MONGO_URI
              value: mongodb://mongo:27017/chat_db
---
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
  ports:
    - port: 5000
      targetPort: 5000
EOF

# Create updated Kubernetes frontend-deployment.yaml
cat << 'EOF' > k8s/frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: ${{ secrets.DOCKER_USERNAME }}/hack-innovate-frontend:latest
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
EOF

# Create the mongo-deployment.yaml file (unchanged)
cat << 'EOF' > k8s/mongo-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
        - name: mongo
          image: mongo:6.0
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongo-data
              mountPath: /data/db
      volumes:
        - name: mongo-data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: mongo
spec:
  selector:
    app: mongo
  ports:
    - port: 27017
      targetPort: 27017
EOF

# Create the updated ci-cd.yaml workflow file
cat << 'EOF' > .github/workflows/ci-cd.yaml
name: Simple CI/CD Pipeline

on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: self-hosted

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push Backend image
        run: |
          docker build -t ${{ secrets.DOCKER_USERNAME }}/hack-innovate-backend:${{ github.sha }} ./backend
          docker tag ${{ secrets.DOCKER_USERNAME }}/hack-innovate-backend:${{ github.sha }} ${{ secrets.DOCKER_USERNAME }}/hack-innovate-backend:latest
          docker push ${{ secrets.DOCKER_USERNAME }}/hack-innovate-backend:${{ github.sha }}
          docker push ${{ secrets.DOCKER_USERNAME }}/hack-innovate-backend:latest

      - name: Build and push Frontend image
        run: |
          docker build -t ${{ secrets.DOCKER_USERNAME }}/hack-innovate-frontend:${{ github.sha }} ./frontend
          docker tag ${{ secrets.DOCKER_USERNAME }}/hack-innovate-frontend:${{ github.sha }} ${{ secrets.DOCKER_USERNAME }}/hack-innovate-frontend:latest
          docker push ${{ secrets.DOCKER_USERNAME }}/hack-innovate-frontend:${{ github.sha }}
          docker push ${{ secrets.DOCKER_USERNAME }}/hack-innovate-frontend:latest

      - name: Deploy to Kubernetes
        run: |
          echo "Applying mongo-deployment.yaml"
          kubectl apply -f k8s/mongo-deployment.yaml
          echo "Applying backend-deployment.yaml"
          kubectl apply -f k8s/backend-deployment.yaml
          echo "Applying frontend-deployment.yaml"
          kubectl apply -f k8s/frontend-deployment.yaml
EOF

echo "All files have been updated with the new image names. ✅"
