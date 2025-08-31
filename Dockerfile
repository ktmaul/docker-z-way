ARG OS_RELEASE=bullseye
FROM --platform=$BUILDPLATFORM debian:${OS_RELEASE}
ARG TARGETPLATFORM

WORKDIR /opt/z-way-server

ENV DEBIAN_FRONTEND=noninteractive

# Block zbw key request
RUN mkdir -p /etc/zbw/flags && touch /etc/zbw/flags/no_connection

RUN apt-get update && \
    apt-get install -qqy --no-install-recommends \
    ca-certificates curl \
    wget procps gpg iproute2 openssh-client openssh-server sudo logrotate && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install z-way-server
# Workaround for expired GPG key
RUN wget -q -O install.sh https://storage.z-wave.me/Z-Way-Install && \
    sed -i 's|deb \${arch_tag}|deb [trusted=yes \${arch_tag//[^0-9A-Za-z=]/}]|g' install.sh

# Restore this line once the GPG key is fixed
#RUN wget -q -O - https://storage.z-wave.me/Z-Way-Install | bash -e && \
RUN cat install.sh | bash -e && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm -f /opt/z-way-server/automation/storage/*

# Unblock zbw
RUN rm /etc/zbw/flags/no_connection
RUN mkdir -p /etc/z-way && echo "zbox" > /etc/z-way/box_type

COPY rootfs/ /

# Add the initialization script
RUN chmod +x /opt/z-way-server/run.sh

EXPOSE 8083

CMD /opt/z-way-server/run.sh
