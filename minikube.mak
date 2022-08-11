# install minikube: https://minikube.sigs.k8s.io/docs/start/

# install istio
# curl -L https://istio.io/downloadIstio | sh -
# export ISTIOPATH=$HOME/istio-1.x.x
# export PATH=$ISTIOPATH/bin:$PATH

# install helm
# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh

# sudo chown -R wshi  /home/wshi/.config/helm/repositories.lock

# kubectl get pods --all-namespaces

KC=kubectl
DK=docker
AWS=aws
IC=istioctl

APP_NS=c756ns
LOG_DIR=logs

S2_VER=v1

DK=docker
HELM=helm
ISTIO_NS=istio-system
RELEASE=c756


default: start provision

start:
	minikube delete
	minikube start

provision: istio prom deploy
# provision: istio prom deploy

istio:
	$(IC) install -y --set profile=demo --set hub=gcr.io/istio-release

# Install Prometheus stack by calling `obs.mak` recursively
prom: init-helm install-prom

init-helm:
	$(HELM) repo add prometheus-community https://prometheus-community.github.io/helm-charts
	$(HELM) repo update

# note that the name $(RELEASE) is discretionary; it is used to reference the install 
# Grafana is included within this Prometheus package
install-prom:
	echo $(HELM) install $(RELEASE) --namespace $(ISTIO_NS) prometheus-community/kube-prometheus-stack 
	$(HELM) install $(RELEASE) -f helm-kube-stack-values.yaml --namespace $(ISTIO_NS) prometheus-community/kube-prometheus-stack 
	$(KC) apply -n $(ISTIO_NS) -f monitoring-lb-services.yaml 
	$(KC) apply -n $(ISTIO_NS) -f cluster/grafana-flask-configmap.yaml 

deploy: appns gw s1 s2 
	# $(KC) -n $(APP_NS) get gw,vs,deploy,svc,pods

appns:
	# Appended "|| true" so that make continues even when command fails
	# because namespace already exists
	$(KC) create ns $(APP_NS) || true
	$(KC) label namespace $(APP_NS) --overwrite=true istio-injection=enabled

# Update service gateway
gw: cluster/service-gateway.yaml
	$(KC) -n $(APP_NS) apply -f $< 

.PHONY: s1
s1: 
	$(KC) -n $(APP_NS) apply -f cluster/s1.yaml 
	# $(KC) -n $(APP_NS) apply -f cluster/s1-sm.yaml 
	$(KC) -n $(APP_NS) apply -f cluster/s1-vs.yaml 

# Update S2 and associated monitoring, rebuilding if necessary
.PHONY: s2
s2: 
	$(KC) -n $(APP_NS) apply -f cluster/s2-dpl-$(S2_VER).yaml | tee $(LOG_DIR)/rollout-s2.log
	$(KC) rollout -n $(APP_NS) restart deployment/cmpt756s2-$(S2_VER) | tee -a $(LOG_DIR)/rollout-s2.log

	$(KC) -n $(APP_NS) apply -f cluster/s2-svc.yaml
	# $(KC) -n $(APP_NS) apply -f cluster/s2-sm.yaml 
	$(KC) -n $(APP_NS) apply -f cluster/s2-vs.yaml 

# Update DB and associated monitoring, rebuilding if necessary
db: 
	$(KC) -n $(APP_NS) apply -f cluster/awscred.yaml 
	$(KC) -n $(APP_NS) apply -f cluster/dynamodb-service-entry.yaml 
	$(KC) -n $(APP_NS) apply -f cluster/db.yaml 
	$(KC) -n $(APP_NS) apply -f cluster/db-sm.yaml 
	$(KC) -n $(APP_NS) apply -f cluster/db-vs.yaml 
