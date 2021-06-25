# demo-keyclaok-kubernetes
Keycloak implementation in loacl Kubernetes environment (minikube).

## Requirements:

- Install virtualBox
- Install minikube
- Install helm
- Install mkcert

## Running:

- Start minikube cluster: ./start-minikube.sh
- Run keycloak server deployment: ./deploy-keycloak.sh
- Run wildfly server deployment: ./deploy-wildfly.sh

## Cleaning up:

If you want to remove a specific keycloak deployment you have to delete the namespace where its deployed.
