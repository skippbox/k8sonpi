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

Kubernetes on RaspberryPI
=========================

This sets up a one node Kubernetes cluster on a RaspberryPI.

For the impatient:
-----------------

1. Clone this repository on your Pi

    $ git clone https://github.com/runseb/k8s4pi.git
    $ cd ./k8s4pi

2. Run the `build.sh` script

    $ ./build.sh

3. Enjoy

The longer version:
-------------------

We use the Kubernetes Kubelet running as a systemd unit to monitor a few Docker containers that make up the Kubernetes _cluster_.
The Kubelet binary for ARM is downloaded and installed in `/usr/bin/kubelet`, a manifest is copied to `/etc/kubernetes/manifests/kubernetes.yaml` which represents a Kubernetes Pod that make up all the required containers.

In this pod we have:

1. An etcd container. Which we run by building an etcd image from scratch on the PI.
2. Several containers based on the Hyperkube image. Hyperkube is a single binary that can start all the Kubernetes components: API server, controller, scheduler.
We build a local Hyperkube image.
3. Then a little trick. Kubernetes does assume that you will run the nodes on x86_64 and automatically pulls an image called the _pause_ container. This container is used to get an IP and share that IP with all the containers in the pod. For the PI, we need to run this pause container on ARM, we trick Kubernetes by building the image `gcr.io/google_containers/pause:0.8.0` locally after having compiled the pause Golang code for ARM.
The ARM binaries for the Kubelet and hyperkube are downloaded from https://github.com/andrewpsuedonym/Kubernetes-Arm-Binaries.git
4. Finally, we download the Kubernetes client `kubectl` for ARM form the official release:

    $ curl -fsSL -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.0.3/bin/linux/arm/kubectl

