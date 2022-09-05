# Roteiro

O que iremos fazer?

## Parte 1
1. Criação de usuário do IAM e permissões
2. Criação da instância do RancherServer pela aws-cli
3. Configuração do Rancher.
4. Configuração do Cluster Kubernetes.
5. Deployment do cluster pela aws-cli.



## Parte 2
6. Configuração do Traefik
7. Configuração do Longhorn
8. Criação do certificado não válido
9. Configuração do ELB
10. Configuração do Route 53


Parabéns, com isso temos a primera parte da nossa infraestrutura. 
Estamos prontos para rodar nossa aplicação.


# Parte 1

## 1 - Criação de usuário do IAM e permissões e configuração da AWS-CLI

https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html


## 2 - Criação da instância do RancherServer pela aws-cli.

```sh 

# RANCHER SERVER

# --image-id              ami-01e7ca2ef94a0ae86
# --instance-type         t3.medium 
# --key-name              multicloud 
# --security-group-ids    sg-0b0e8363b215900f0 
# --subnet-id             subnet-4f5e7705

$ aws ec2 run-instances --image-id ami-01e7ca2ef94a0ae86 --count 1 --instance-type t3.medium --key-name multicloud --security-group-ids sg-0b0e8363b215900f0 --subnet-id subnet-67c83f0e --user-data file://rancher.sh --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rancherserver}]' 'ResourceType=volume,Tags=[{Key=Name,Value=rancherserver}]' 

```


## 3 - Configuração do Rancher
Acessar o Rancher e configurar

https://3.134.108.244

## 4 - Configuração do Cluster Kubernetes.
Criar o cluster pelo Rancher e configurar.



## 5 - Deployment do cluster pela aws-cli

```sh
# --image-id ami-01e7ca2ef94a0ae86
# --count 3 
# --instance-type t3.large 
# --key-name multicloud 
# --security-group-ids sg-0b0e8363b215900f0 
# --subnet-id subnet-09c5a4961e6056757 
# --user-data file://k8s.sh

$ aws ec2 run-instances --image-id ami-01e7ca2ef94a0ae86 --count 3 --instance-type t3.large --key-name multicloud --security-group-ids sg-0b0e8363b215900f0 --subnet-id subnet-67c83f0e --user-data file://k8s.sh   --block-device-mapping "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 70 } } ]" --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=k8s}]' 'ResourceType=volume,Tags=[{Key=Name,Value=k8s}]'     
```

Instalar o kubectl 

https://kubernetes.io/docs/tasks/tools/


# Parte 2

## 6 - Configuração do Traefik

O Traefik é a aplicação que iremos usar como ingress. Ele irá ficar escutando pelas entradas de DNS que o cluster deve responder. Ele possui um dashboard de  monitoramento e com um resumo de todas as entradas que estão no cluster.
```sh
$ kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-rbac.yaml
$ kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-ds.yaml
$ kubectl --namespace=kube-system get pods
```
Agora iremos configurar o DNS pelo qual o Traefik irá responder. No arquivo ui.yml, localizar a url, e fazer a alteração. Após a alteração feita, iremos rodar o comando abaixo para aplicar o deployment no cluster.
```sh
$ kubectl apply -f traefik.yaml
```


## 7 - Configuração do Longhorn
Pelo console do Rancher


## 8 - Criação do certificado
Criar certificado para nossos dominios:

 *.viniciusschulz.com.br


```sh
> openssl req -new -x509 -keyout cert.pem -out cert.pem -days 365 -nodes
Country Name (2 letter code) [AU]:DE
State or Province Name (full name) [Some-State]:Germany
Locality Name (eg, city) []:nameOfYourCity
Organization Name (eg, company) [Internet Widgits Pty Ltd]:nameOfYourCompany
Organizational Unit Name (eg, section) []:nameOfYourDivision
Common Name (eg, YOUR name) []:*.example.com
Email Address []:webmaster@example.com
```

arn:aws:acm:us-east-1:007345297893:certificate/303f1823-ecc4-43d9-b7b7-af645110a97d


## 9 - Configuração do ELB


```sh
# LOAD BALANCER

# !! ESPECIFICAR O SECURITY GROUPS DO LOAD BALANCER

# --subnets subnet-4f5e7705 subnet-67c83f0e

$ aws elbv2 create-load-balancer --name multicloud --type application --subnets subnet-05cef53ddc1910c3f subnet-0fe220c744a443382
#	 "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-east-1:007345297893:loadbalancer/app/multicloud/57211a2ff33263f9"

# --vpc-id vpc-02eba66e2a23c8a9b

$ aws elbv2 create-target-group --name multicloud --protocol HTTP --port 80 --vpc-id vpc-02eba66e2a23c8a9b --health-check-port 8080 --health-check-path /api/providers
#	 "TargetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:007345297893:targetgroup/multicloud/b3d1eed4d9b6532d"
	
	
# REGISTRAR OS TARGETS  
$ aws elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:us-east-1:007345297893:targetgroup/multicloud/b3d1eed4d9b6532d --targets Id=i-000805da4b2f1dbaf Id=i-028d3d52a3f006fd5


i-000805da4b2f1dbaf
i-028d3d52a3f006fd5


# ARN DO Certificado - arn:aws:acm:us-east-1:984102645395:certificate/fa016001-254f-4127-b51a-61588b15c555
# HTTPS - CRIADO PRIMEIRO
$ aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:007345297893:loadbalancer/app/multicloud/57211a2ff33263f9 \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=arn:aws:acm:us-east-1:007345297893:certificate/303f1823-ecc4-43d9-b7b7-af645110a97d   \
    --ssl-policy ELBSecurityPolicy-2016-08 --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:007345297893:targetgroup/multicloud/b3d1eed4d9b6532d
#  "ListenerArn": "arn:aws:elasticloadbalancing:us-east-1:007345297893:listener/app/multicloud/57211a2ff33263f9/78fc2b81c514b618"


$ aws elbv2 describe-target-health --target-group-arn targetgroup-arn

# DESCRIBE NO LISTENER
$ aws elbv2 describe-listeners --listener-arns arn:aws:elasticloadbalancing:us-east-1:984102645395:listener/app/multicloud/0c7e036793bff35e/a7386cf3e0dc3c0e


```


## 10 - Configuração do Route 53
Pelo console da AWS



