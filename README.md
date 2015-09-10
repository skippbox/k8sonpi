<!---
   Copyright {yyyy} {name of copyright owner}

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
--->

K8S on RaspberryPI
==================

1. pause container for ARM, compile and tag to gcr.io/google_containers/pause   0.8.0 

https://github.com/kubernetes/kubernetes/tree/5520386b180d3ddc4fa7b7dfe6f52642cc0c25f3/build/pause

compile pause.go using hypriot/rpi-golang image and mount volume from host

    go build --ldflags '-extldflags "-static" -s' pause.go

then

    docker build -t  gcr.io/google_containers/pause:0.8.0 .

2. compile etcd with golang base image from hypriot

FROM hypriot/rpi-golang

RUN mkdir -p /go/src/app
RUN mkdir -p /var/lib/etcd
WORKDIR /go/src/app

# this will ideally be built by the ONBUILD below ;)
CMD ["go-wrapper", "run"]

COPY . /go/src/app
RUN mv /go/src/app/go-wrapper /goroot/bin/go-wrapper
RUN chmod +x /goroot/bin/go-wrapper
RUN go-wrapper download
RUN go-wrapper install

ENTRYPOINT ["etcd"]

EXPOSE 4001 7001 2379 2380

docker build -t etcd .

3. create hyperkube image

FROM resin/rpi-raspbian:wheezy

RUN apt-get update
RUN apt-get -yy -q install iptables ca-certificates

COPY hyperkube /hyperkube

docker build -t hyperkube .

4. Create kubelet system service in /etc/systemd/system/kubelet.service

Grab the binary from https://github.com/andrewpsuedonym/Kubernetes-Arm-Binaries.git

curl -fsSL -o hyperkube https://github.com/andrewpsuedonym/Kubernetes-Arm-Binaries/raw/master/hyperkube

$ cat /etc/systemd/system/kubelet.service 
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/bin/kubelet  \
--api-servers=http://127.0.0.1:8080 \
--allow-privileged=true \
--config=/etc/kubernetes/manifests \
--v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target 

5. Create the manifests and put it in /etc/kubernetes/manifests/kubernetes.yaml

mkdir -p /etc/kubernetes/manifests

apiVersion: v1
kind: Pod
metadata: 
  name: kube-controller
spec: 
  hostNetwork: true
  containers: 
    - name: "etcd"
      image: "etcd"
      args: 
        - "--data-dir=/var/lib/etcd"
        - "--advertise-client-urls=http://127.0.0.1:2379"
        - "--listen-client-urls=http://127.0.0.1:2379"
        - "--listen-peer-urls=http://127.0.0.1:2380"
        - "--name=etcd"
    - name: "kube-apiserver"
      image: "hyperkube"
      args: 
        - "/hyperkube"
        - "apiserver"
        - "--allow-privileged=true"
        - "--etcd-servers=http://127.0.0.1:2379"
        - "--insecure-bind-address=0.0.0.0"
        - "--service-cluster-ip-range=10.200.20.0/24"
        - "--v=2"
    - name: "kube-controller-manager"
      image: "hyperkube"
      args: 
        - "/hyperkube"
        - "controller-manager"
        - "--master=http://127.0.0.1:8080"
        - "--v=2"
    - name: "kube-scheduler"
      image: "hyperkube"
      args:
        - "/hyperkube"
        - "scheduler"
        - "--master=http://127.0.0.1:8080"
        - "--v=2"
    - name: "kube-proxy"
      image: "hyperkube"
      args:
        - "/hyperkube"
        - "proxy"
        - "--master=http://127.0.0.1:8080"
        - "--bind-address=0.0.0.0"
        - "--v=2"
      securityContext:
        privileged: true

6. Get kubectl for ARM

curl -fsSL -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.0.3/bin/linux/arm/kubectl

