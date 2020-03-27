ARG BASE_REGISTRY=nexus-docker-secure.levelup-nexus.svc.cluster.local:18082
ARG BASE_IMAGE=redhat/ubi/ubi7
ARG BASE_TAG=7.8

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

LABEL name="RKE Tools" \
      maintainer="Rancher Labs <support@rancher.com>" \
      vendor="Rancher" \
      version="0.1.52" \
      release="1" \
      summary="RKE Tools" \
      description="RKE Tools"

COPY LICENSE /licenses/rke-tools

USER root

RUN yum update -y && \
    yum install -y ca-certificates system acl && \
    mkdir -p /opt/rke-tools/bin /etc/confd /opt/cni/bin /tmp/etcd

# Add TARs to TMP and expand them if desired
ADD docker.tgz /tmp
ADD cni.tgz /tmp
COPY etcd.tgz /tmp

# Add other binaries to the right locations
ADD confd /usr/local/bin/confd
ADD portmap /tmp/portmap

# Move files around and perform clean-up
RUN cp -r /tmp/docker/* /opt && \
    tar zxvf /tmp/etcd.tgz -C /tmp/etcd --strip-components=1 && \
    ls -la /tmp/etcd && \
    mv /tmp/etcd/etcdctl /usr/local/bin/etcdctl && \
    rm -rf /tmp/etcd

# Copy in other necessary files from project
COPY templates /etc/confd/templates/
COPY conf.d /etc/confd/conf.d/
COPY cert-deployer nginx-proxy /usr/bin/
COPY entrypoint.sh cloud-provider.sh weave-plugins-cni.sh /opt/rke-tools/
#COPY rke-etcd-backup /opt/rke-tools

# Define volume
VOLUME /opt/rke-tools

# Update ownership of files/directories
RUN chown -R 2000:2000 /opt/rke-tools /etc/confd && \
    chown 2000:2000 /usr/local/bin/etcdctl /usr/bin/cert-deployer /usr/bin/nginx-proxy && \
    chown 2000:2000 /tmp/portmap /tmp/loopback

USER 2000

CMD ["/bin/bash"]