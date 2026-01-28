# OpenWrt Build Environment for SL-3000 (MT7981)
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV FORCE_UNSAFE_CONFIGURE=1

# Install required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    clang \
    flex \
    bison \
    g++ \
    gawk \
    gcc-multilib \
    g++-multilib \
    gettext \
    git \
    libncurses5-dev \
    libssl-dev \
    python3-distutils \
    rsync \
    unzip \
    zlib1g-dev \
    file \
    wget \
    curl \
    vim \
    nano \
    sudo \
    time \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create build user
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/builder
USER builder

# Clone ImmortalWrt source (supports MT7981/SL-3000)
RUN git clone --depth 1 -b openwrt-24.10 https://github.com/immortalwrt/immortalwrt.git

WORKDIR /home/builder/immortalwrt

# Copy configuration files
COPY --chown=builder:builder .config /home/builder/immortalwrt/.config
COPY --chown=builder:builder build.sh /home/builder/immortalwrt/build.sh

# Make build script executable
RUN chmod +x /home/builder/immortalwrt/build.sh

# Update and install feeds
RUN ./scripts/feeds update -a && \
    ./scripts/feeds install -a

# Download packages
RUN make download -j$(nproc) V=s || true

# Start build
CMD ["/home/builder/immortalwrt/build.sh"]
