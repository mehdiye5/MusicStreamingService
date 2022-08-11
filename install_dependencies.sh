#!/bin/sh

if [ "$1" == "k8s" ]
then
    #installing k8s
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    kubectl version --client
fi

if [ "$1" == "eks" ]
then
    #installing eks dependency
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
    eksctl version
fi

if [ "$1" == "istio" ]
then
    #installing istio depency
    curl -L https://istio.io/downloadIstio | sh -
    export PATH=$HOME/istio-1.13.2/bin:$PATH
fi

if [ "$1" == "helm" ]
then
    #install helm
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
fi