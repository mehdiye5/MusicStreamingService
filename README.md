# CMPT756-Term-Project-GPU-Snobs

# Project Commands

## Preliminary Requirement
- **Note** the services were tested on Ubuntu, to get the best results make sure to run on the same OS. Also if you would like to replicate our Grafana dashboard please import the dashboard we have in the **grafana-custom-dashboard** directory and change the pod id in the edit section.
1. Make sure that aws cli is installed, if not follow the instruction in the link below
  - https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
2. Login to aws, by using following command
> $ aws configure <br>
AWS Access Key ID [None]: accesskey <br>
AWS Secret Access Key [None]: secretkey <br>
Default region name [None]: us-west-2 <br>
Default output format [None]: json
3. Check if all the dependencies are installed.
- Make sure that k8s is installed by executing following command
>kubectl version --client
- Make sure that eks is installed by executing following command
>eksctl version
- Make sure that istio is installed by executing following command
>istioctl
- Make sure that helm is installed by executing following command
> helm
4. NOTE: if you were missing any of the dependencies and had to istall it, make sure to stay in the same terminal window when running the service and you are in the following directory "CMPT756-Term-Project-GPU-Snobs"
- To install kubkectl run
> make install_kubctl
- To install eksctl run
> make install_eks_ctl
- To install istio run
> make install_istio
- To install helm run
> make install_helm

5. Make sure that "logs/gw.log" has rwx priveleges
6. In the "cluster" directory make sure that "ghcr.io-token.txt" file has your token value
7. Rename "cluster/tpl-vars-blank.txt" file to "cluster/tpl-vars.txt" and fill out all the required fields

## Single Command Run Services
> make all

## Preliminary Set up (Before scripts)
1. Start service
  - make -f eks.mak start

2. Provision services and set Kubectl context
  - make -f k8s.mak provision
  - kubectl config set-context --current --namespace=c756ns

3. Print grafana URL
  - make -f k8s.mak grafana-url

4. Create gatling-1-music.sh
  - vim -> 
    #!/usr/bin/env bash
    docker container run --detach --rm \
      -v ${PWD}/gatling/results:/opt/gatling/results \
      -v ${PWD}/gatling:/opt/gatling/user-files \
      -v ${PWD}/gatling/target:/opt/gatling/target \
      -e CLUSTER_IP=`tools/getip.sh kubectl istio-system svc/istio-ingressgateway` \
      -e USERS=1 \
      -e SIM_NAME=ReadMusicSim \
      -label gatling \
      ghcr.io/scp-2021-jan-cmpt-756/gatling:3.4.2 \
      -s proj756.ReadMusicSim

5. Make gatling-1-music.sh runnable
  - chmod u+x gatling-1-music.sh


## Push image service s3 to ghcr

0. Cd to s3 folder
  - cd s3

1. Build the image
  - docker image build --platform linux/amd64 -t cmpt756s3 .

2. Login to ghcr
  - cat ../cluster/ghcr.io-token.txt | docker login ghcr.io -u `<REGID>` --password-stdin

3. Tag the image
  - docker image tag cmpt756s3 ghcr.io/`<REGID>`/cmpt756s3:v1

4. Push the image
  - docker image push ghcr.io/`<REGID>`/cmpt756s3:v1

5. Validate that the image is updated in github

6. Make the image public in github

## Manually Deploy the service to cluster

  - kubectl -n c756ns apply -f cluster/s3.yaml | tee logs/s3.log
