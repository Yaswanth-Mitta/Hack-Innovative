#!/bin/bash

echo "Starting port number modifications..."

# --- Update Backend files ---
echo "Modifying backend/app.py..."
sed -i 's/port=5000/port=5001/g' backend/app.py
sed -i 's/mongodb:\/\/mongo:27017/mongodb:\/\/mongo:27018/g' backend/app.py

echo "Modifying backend/Dockerfile..."
sed -i 's/EXPOSE 5000/EXPOSE 5001/g' backend/Dockerfile

# --- Update Frontend files ---
echo "Modifying frontend/nginx.conf..."
sed -i 's/listen 80/listen 8080/g' frontend/nginx.conf
sed -i 's/proxy_pass http:\/\/backend:5000/proxy_pass http:\/\/backend:5001/g' frontend/nginx.conf

echo "Modifying frontend/Dockerfile..."
sed -i 's/EXPOSE 80/EXPOSE 8080/g' frontend/Dockerfile

# --- Update Kubernetes files ---
echo "Modifying k8s/backend-deployment.yaml..."
sed -i 's/containerPort: 5000/containerPort: 5001/g' k8s/backend-deployment.yaml
sed -i 's/port: 5000/port: 5001/g' k8s/backend-deployment.yaml
sed -i 's/targetPort: 5000/targetPort: 5001/g' k8s/backend-deployment.yaml
sed -i 's/mongodb:\/\/mongo:27017/mongodb:\/\/mongo:27018/g' k8s/backend-deployment.yaml

echo "Modifying k8s/frontend-deployment.yaml..."
sed -i 's/containerPort: 80/containerPort: 8080/g' k8s/frontend-deployment.yaml
sed -i 's/port: 80/port: 8080/g' k8s/frontend-deployment.yaml
sed -i 's/targetPort: 80/targetPort: 8080/g' k8s/frontend-deployment.yaml
sed -i 's/nodePort: 30080/nodePort: 30081/g' k8s/frontend-deployment.yaml

echo "Modifying k8s/mongo-deployment.yaml..."
sed -i 's/containerPort: 27017/containerPort: 27018/g' k8s/mongo-deployment.yaml
sed -i 's/port: 27017/port: 27018/g' k8s/mongo-deployment.yaml
sed -i 's/targetPort: 27017/targetPort: 27018/g' k8s/mongo-deployment.yaml

echo "All port modifications complete! Please review your files before pushing."
