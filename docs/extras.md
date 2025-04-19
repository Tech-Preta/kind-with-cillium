# Como instalar o Metrics Server

O Metrics Server é uma fonte escalável e eficiente de métricas de recursos de contêiner para pipelines de autoscaling integrados do Kubernetes. O Metrics Server coleta métricas de recursos dos Kubelets e as expõe no apiserver do Kubernetes através da Metrics API, para uso pelo Horizontal Pod Autoscaler e Vertical Pod Autoscaler.

O Metrics Server não deve ser usado para finalidades que não envolvam autoscaling. Por exemplo, não o utilize para encaminhar métricas para soluções de monitoramento ou como fonte de métricas para soluções de monitoramento.

O Metrics Server é implantado como um Deployment no namespace kube-system.

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

# Como instalar o ArgoCD
O ArgoCD é uma ferramenta declarativa de entrega contínua GitOps para Kubernetes. Ele permite gerenciar seus recursos Kubernetes usando repositórios Git como fonte da verdade.

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Acessando o Servidor de API do Argo CD
Por padrão, o servidor de API do Argo CD não é exposto com um IP externo. Para acessar o servidor de API, escolha uma das seguintes técnicas para expor o servidor de API do Argo CD:

Altere o tipo do serviço argocd-server para LoadBalancer:
```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```
Isso criará um serviço LoadBalancer que expõe o servidor de API do Argo CD com um IP externo. Você poderá acessar o servidor de API usando o IP externo do serviço LoadBalancer.
Alternativamente, você pode usar o port-forward para acessar o servidor de API:
```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Para obter o usuário e senha padrão do Argo CD, execute o seguinte comando:
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d
```

