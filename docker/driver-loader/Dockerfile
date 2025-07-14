ARG FALCO_IMAGE_TAG=latest
FROM ghcr.io/grafana/falco:${FALCO_IMAGE_TAG}

LABEL org.opencontainers.image.source='https://github.com/grafana/falco/tree/master/docker/driver-loader/Dockerfile' \
      org.opencontainers.image.licenses='Apache-2.0'

LABEL usage="docker run -i -t --privileged -v /root/.falco:/root/.falco -v /proc:/host/proc:ro -v /boot:/host/boot:ro -v /lib/modules:/host/lib/modules:ro -v /usr:/host/usr:ro -v /etc:/host/etc:ro ghcr.io/grafana/falco-driver-loader:latest [driver] [options]"

ENTRYPOINT [ "sh", "-c", "/usr/bin/falcoctl driver config --type modern_ebpf && /usr/bin/falcoctl driver install --compile=false --download=false" ]
