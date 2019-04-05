#!/bin/bash

# Creating AKS Cluster with Kafa cluster 

usage() { echo "Usage: setup_cluster.sh -n <clusterName> -r <resourceGroupName> -l <location> -s <vmSize> "}

declare clusterName=""
declare resourceGroupName=""
declare location="westus2"
declare vmSize="Standard_D4s_v3"

while getopts ":n:r:l:s:" arg; do
    case "${arg}" in
      n)
          clusterName=${OPTARG}
          ;;
      r)
          resourceGroupName=${OPTARG}
          ;;
      l)
          location=${OPTARG}
          ;;
      s)
          vmSize=${OPTARG}
          ;;
    esac
done

shift $((OPTIND-1))

if [[ -z "$clusterName" ]]; then
    echo "Can not find the clusterName"
    echo "Enter the clusterName"
    usage
fi 

if [[ -z "$resourceGroupName" ]]; then
    echo "Can not find the resourceGroupName"
    echo "Enter the resourceGroupName"
    usage
fi 

echo "Cluster Name   : $clusterName"
echo "Resource Group : $resourceGroupName"
echo "Location       : $location"
echo "Node VM size   : $vmSize"

echo "Creating Resource Group..."
az group create -n $resourceGroupName -l $location
if [[ $? != 0 ]]; then 
  exit 1
fi

echo "Creating AKS Cluster..."
az aks create -n $clusterName -g $resourceGroupName -l $location  -s $vmSize --generate-ssh-keys 
if [[ $? != 0 ]]; then 
  exit 1
fi

echo "Getting Credentials for AKS cluster..."
az aks get-credentials --name $clusterName --resource-group $resourceGroupName
if [[ $? != 0 ]]; then 
  exit 1
fi

# helm is already installed
echo "Installing helm tiller..."
helm init
if [[ $? != 0 ]]; then 
  exit 1
fi

echo "Installing Kafka clsuter...."
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
if [[ $? != 0 ]]; then 
  exit 1
fi

helm install --name my-kafka incubator/kafka --set replicas=1,prometheus.jmx.enabled=true,prometheus.kafka.enabled=true
if [[ $? != 0 ]]; then 
  exit 1
fi

exit 0
