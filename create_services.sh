#!/usr/bin/env bash

# make templates
make -f k8s-tpl.mak templates

# clean the logs
rm ./logs/*

# start services
make -f eks.mak start

# clean dynamo-db stack
make -f k8s.mak dynamodb-clean

# start previsions
make -f k8s.mak provision

# prevision context
kubectl config set-context --current --namespace=c756ns

# create and deploy metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# deploy autoscaling for db service
kubectl create -f ./cluster/10-db-cpu-hpa.yaml

# deploy autoscaling for s1 service
kubectl create -f ./cluster/10-s1-hpa.yaml

# deploy autoscaling for s2 service
kubectl create -f ./cluster/10-s2-hpa.yaml

# deploy autoscaling for s3 service
kubectl create -f ./cluster/10-s3-hpa.yaml

# print grafana url
make -f k8s.mak grafana-url

#print kiali url
make -f k8s.mak kiali-url

#print prometheus url
make -f k8s.mak prometheus-url
