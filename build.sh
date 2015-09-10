#!/bin/bash
#   Copyright {yyyy} {name of copyright owner}
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

git clone https://github.com/coreos/etcd.git
cp Dockerfile.etcd ./etcd/Dockerfile
cd etcd
docker build -t etcd .

cd ../pause
docker run -v .:/tmp/pause -w /tmp/pause hypriot/rpi-golang go build --ldflags '-extldflags "-static" -s' pause.go
docker build -t -t  gcr.io/google_containers/pause:0.8.0 .

cd ../
curl -fsSL -o hyperkube https://github.com/andrewpsuedonym/Kubernetes-Arm-Binaries/raw/master/hyperkube
curl -fsSL -o kubelet https://github.com/andrewpsuedonym/Kubernetes-Arm-Binaries/raw/master/kubelet

docker build -f Dockerfile.hyperkube -t hyperkube .

cp kubelet.service /etc/systemd/system/kubelet.service
mkdir -p /etc/kubernetes/manifests
cp kubernetes.yaml /etc/kubernetes/manifests/kubernetes.yaml
mv kubelet /usr/bin/kubelet
chmod +x /usr/bin/kubelet

curl -fsSL -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.0.3/bin/linux/arm/kubectl
chmod +x kubectl





