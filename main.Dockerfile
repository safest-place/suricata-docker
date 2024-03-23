FROM ubuntu:22.04 as install

RUN mkdir -p /root/.cargo/
COPY cargo_config /root/.cargo/config
RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    build-essential \
    git \
    libpcre3 \
    libpcre3-dbg \
    libpcre3-dev \
    libtool \
    libpcap-dev \
    libnet1-dev \
    libyaml-0-2 \
    libyaml-dev \
    libmagic-dev \
    libcap-ng-dev \
    libjansson-dev \
    pkg-config \
    python3 \
    python3-pip \
    zlib1g \
    zlib1g-dev \
    libpcre2-dev \
    rustc \
    cargo \
    liblz4-dev \
    libunwind-dev \
    wget \
    curl \
    --no-install-recommends

WORKDIR /opt
RUN git clone https://github.com/OISF/suricata.git /opt/suricata-git
WORKDIR /opt/suricata-git
RUN git clone https://github.com/OISF/libhtp
RUN cargo install -f cbindgen --root /usr/

RUN ./autogen.sh && \
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var && \
    make && \
    make install-full && \
    ldconfig

FROM ubuntu:22.04

RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN apt-get update && apt-get install -y \
    libpcre3 \
    libpcre3 \
    libtool \
    libpcap0.8 \
    libnet1 \
    libyaml-0-2 \
    libyaml-dev \
    libmagic1 \
    libcap-ng0 \
    libjansson4 \
    python3 \
    python3-pip \
    zlib1g \
    libunwind8 \
    jq \
    wget \
    curl \
    net-tools \
    tzdata \
    ca-certificates \
    logrotate \
    vim \
    dumb-init \
    --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=install /etc/suricata /etc/suricata
COPY --from=install /var/log/suricata /var/log/suricata
COPY --from=install /usr/include/htp /usr/include/htp
COPY --from=install /usr/lib/libhtp.a /usr/lib/libhtp.a
COPY --from=install /usr/lib/libhtp.la /usr/lib/libhtp.la
COPY --from=install /usr/lib/libhtp.so /usr/lib/libhtp.so
COPY --from=install /usr/lib/libhtp.so.2 /usr/lib/libhtp.so.2
COPY --from=install /usr/lib/libhtp.so.2.0.0 /usr/lib/libhtp.so.2.0.0
COPY --from=install /usr/include/htp /usr/include/htp

COPY --from=install /usr/bin/suricata /usr/bin/suricata

RUN pip3 install --upgrade \
    setuptools \
    wheel
RUN pip3 install --pre \
    suricata-update \
    pyyaml

RUN suricata-update
COPY entrypoint.sh /var/lib/suricata/
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/bin/bash", "/var/lib/suricata/entrypoint.sh"]

