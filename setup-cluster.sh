# setup-cluster.sh
#!/bin/bash
set -e

# Checagem de pré-requisitos
command -v kind >/dev/null || { echo "Kind não instalado"; exit 1; }
command -v helm >/dev/null || { echo "Helm não instalado"; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl não instalado"; exit 1; }

# Apaga cluster antigo
kind delete cluster || true

# Cria cluster
kind create cluster --config kind.yaml

# Atualiza kubeconfig
kind get kubeconfig > ~/.kube/config

# Instala Cilium
helm upgrade --install --namespace kube-system --repo https://helm.cilium.io cilium cilium --values - <<EOF
kubeProxyReplacement: true
k8sServiceHost: kind-control-plane
k8sServicePort: 6443
hostServices:
  enabled: false
externalIPs:
  enabled: true
nodePort:
  enabled: true
hostPort:
  enabled: true
image:
  pullPolicy: IfNotPresent
ipam:
  mode: kubernetes
hubble:
  enabled: true
EOF

# Instala Cilium CLI
chmod +x install-cilium-cli.sh
./install-cilium-cli.sh

# Instala MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl apply -f metallb-config.yaml

# Instala Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Instala ArgoCD
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Instala ingress-nginx
helm upgrade --install --namespace ingress-nginx --create-namespace --repo https://kubernetes.github.io/ingress-nginx ingress-nginx ingress-nginx --values - <<EOF
defaultBackend:
  enabled: true
EOF

echo "Cluster pronto!"