# kind-with-cillium

Este projeto configura um cluster Kubernetes usando Kind e Cilium como CNI. Inclui também a instalação do ingress-nginx e MetalLB para balanceamento de carga.

## Pré-requisitos

- [Docker](https://www.docker.com/)
- [Kind](https://kind.sigs.k8s.io/)
- [Helm](https://helm.sh/)

Siga o passo a passo disponível em [kind.md](docs/kind.md) para criar o cluster Kubernetes com o Kind, instalar o Cilium, ingress-nginx e MetalLB.

Essa configuração é útil para desenvolvimento local e testes de aplicações. Assim é possível criar `ingress` e `service` do tipo `LoadBalancer` no cluster local e acessar as aplicações através do endereço IP do MetalLB.

Utilizamos `${LB_IP}.nip.io` para ter um endereço DNS que resolve o endereço IP do MetalLB. O `nip.io` é um serviço gratuito que resolve o endereço IP do MetalLB para o endereço IP do host. 

## Contribuição

Sinta-se à vontade para abrir issues e pull requests para melhorias e correções.

