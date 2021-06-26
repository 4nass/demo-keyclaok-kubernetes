#!/bin/bash

# Start Minikube on VirtualBox with CRI-O runtime
minikube start --driver=virtualbox --container-runtime=cri-o --no-vtx-check
