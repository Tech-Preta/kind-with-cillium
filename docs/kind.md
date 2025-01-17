# Criando um cluster Kubernetes com o Kind, Cillium e MetalLB

## Introdução

O [Kind](https://kind.sigs.k8s.io/) é uma ferramenta para executar clusters Kubernetes em contêineres Docker. Ele foi projetado para uso em testes, CI e desenvolvimento. O Kind foi criado para ser uma alternativa leve e fácil de usar para executar clusters Kubernetes.

O [Cilium](https://cilium.io/) é uma solução de rede e segurança para Kubernetes baseada em eBPF. Ele fornece uma solução de rede e segurança de alto desempenho, escalável e confiável para Kubernetes. O Cilium é uma alternativa ao kube-proxy e ao iptables.

Neste tutorial, você aprenderá como criar um cluster Kubernetes com o Kind e instalar o Cilium para gerenciar a rede e a segurança do cluster.

## Pré-requisitos

- Docker
- Kubectl
- Kind
- Helm

## Criando um cluster Kubernetes com o Kind

```
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
networking:
  disableDefaultCNI: true
  kubeProxyMode: none
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
- role: worker
```
## Obtenha o Kubeconfig

```
kind get kubeconfig > ~/.kube/config
```

## Verificando o cluster

```
kubectl get nodes
kubectl get pods -n kube-system
```

Os nós workers não estarão prontos até que o Cilium seja instalado, visto que o Cilium será o responsável pela rede do cluster.

## Instalando o Cilium

```
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
  relay:
    enabled: true
  ui:
    enabled: true
    ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: nginx
      hosts:
        - hubble-ui.127.0.0.1.nip.io
EOF
```

Agora verifique o namespace `kube-system` para ver se os pods do Cilium estão em execução.

```
kubectl get pods -n kube-system
```

## Instalação do Cilium CLI

Execute o comando abaixo para instalar a cli do Cilium.

```
chmod +x install-cilium-cli.sh
./install-cilium-cli.sh
cilium status --wait
```

## Instalando o MetalLB

O [MetalLB](https://metallb.universe.tf/) é um controlador de balanceamento de carga de metal para Kubernetes. Ele fornece uma solução de balanceamento de carga de camada 2 para clusters Kubernetes. O MetalLB é uma alternativa ao serviço LoadBalancer do Kubernetes.

```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
```

Agora vamos verificar a configuração de endereçamento IP (IPAM) da rede docker chamada kind.

```
docker network inspect -f '{{.IPAM.Config}}' kind
```
A saída será algo como:

```
[{fc00:f853:ccd:e793::/64   map[]} {172.18.0.0/16  172.18.0.1 map[]}]
```

E com base nessa saída definimos o range de IPs para utilizar no arquivo de configuração do MetalLB.

```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: example
  namespace: metallb-system
spec:
  addresses:
    - 172.18.255.200-172.18.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: metallb-system
```

Agora vamos criar um service do tipo LoadBalancer para testar o MetalLB.

```
kubectl create service loadbalancer my-lbs --tcp=80:8080
```

Agora vamos verificar se o serviço foi criado e se o IP foi atribuído.

```
kubectl get svc my-lbs
```

A saída será algo como:

```
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
kubernetes   ClusterIP      10.96.0.1      <none>           443/TCP        68m
my-lbs       LoadBalancer   10.96.187.92   172.18.255.150   80:30225/TCP   40s
```



## Instalando o Ingress Controller

O Ingress Controller é responsável por gerenciar o tráfego de entrada para o cluster Kubernetes. O Ingress Controller é um componente essencial para permitir o acesso externo aos serviços em execução no cluster. 

### Instalar ingress-nginx
```
helm upgrade --install --namespace ingress-nginx --create-namespace --repo https://kubernetes.github.io/ingress-nginx ingress-nginx ingress-nginx --values - <<EOF
defaultBackend:
  enabled: true
EOF
```

### Criar um Ingress para expor o serviço do Hubble-UI
```
LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
helm upgrade --namespace kube-system --repo https://helm.cilium.io cilium cilium --reuse-values --values - <<EOF
hubble:
  ui:
    enabled: true
    ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: nginx
      hosts:
        - hubble-ui.${LB_IP}.nip.io
EOF
```

### Acessando o Hubble-UI

```
echo "http://hubble-ui.${LB_IP}.nip.io"
```

