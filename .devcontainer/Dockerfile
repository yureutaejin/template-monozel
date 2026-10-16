# ubuntu:noble-20260917 multi-architecture image digest
FROM docker.io/library/ubuntu@sha256:534baea6a22c03a63003dbc8dbe78fe34bc0d7e595d9a9dc9834884ff530eb55 AS base

ARG TARGETOS
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------------------------------------------------------
# MARK: General

RUN <<EOF
  set -eu
  echo 'path-exclude=/usr/share/doc/*' > /etc/dpkg/dpkg.cfg.d/01_nodoc
  echo 'path-exclude=/usr/share/man/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc
  rm -rf /usr/share/doc /usr/share/man
  apt-get update
  apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    curl \
    git \
    ssh \
    sudo \
    vim \
    tar \
    wget \
    buildah \
    fuse-overlayfs \
    runc
  rm -rf /var/lib/apt/lists/*
EOF

RUN mkdir -p /etc/ssh /etc/sudoers.d

RUN echo 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl' \
    >> /etc/ssh/ssh_known_hosts

RUN echo 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl' \
    >> /etc/ssh/ssh_known_hosts

# --------------------------------------------------------------------------------------------------
# MARK: Bazel and its tools

ARG BAZELISK_VERSION=1.29.0
RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-${TARGETARCH} \
    -O /usr/local/bin/bazel \
    && chmod +x /usr/local/bin/bazel
RUN bazel help completion bash > /usr/share/bash-completion/completions/bazel

ARG BUILDIFIER_VERSION=10.1.0
RUN wget https://github.com/bazelbuild/buildtools/releases/download/v${BUILDIFIER_VERSION}/buildifier-linux-${TARGETARCH} \
    -O /usr/local/bin/buildifier \
    && chmod +x /usr/local/bin/buildifier

FROM base AS dev

# --------------------------------------------------------------------------------------------------
# MARK: User tools and config

ARG STARSHIP_VERSION=1.26.0
RUN curl -fsSL \
    https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-$(uname -m)-unknown-linux-musl.tar.gz \
    | tar xz -C /usr/local/bin \
    && echo 'eval "$(/usr/local/bin/starship init bash)"' >> /etc/bash.bashrc

ARG APM_VERSION=latest
RUN <<EOF
  curl -fsSL https://github.com/microsoft/apm/releases/download/${APM_VERSION}/apm-linux-${TARGETARCH}.tar.gz | tar -xz -C /usr/local/lib/
  mv /usr/local/lib/apm-${TARGETOS}-${TARGETARCH} /usr/local/lib/apm
  ln -sf /usr/local/lib/apm/apm /usr/local/bin/apm
EOF

ARG USERNAME=vscode
ARG USER_UID=1001
ARG USER_GID=${USER_UID}
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} --shell /bin/bash \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}
