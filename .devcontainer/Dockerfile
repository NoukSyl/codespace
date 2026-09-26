FROM archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        base-devel \
        bash \
        ca-certificates \
        coreutils \
        curl \
        docker \
        findutils \
        git \
        grep \
        iproute2 \
        iputils \
        jq \
        less \
        nano \
        openssh \
        procps-ng \
        rsync \
        sed \
        sudo \
        tar \
        unzip \
        util-linux \
        vim \
        which \
        gzip && \
    pacman -Scc --noconfirm

RUN useradd -m -s /bin/bash vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode && \
    chmod 440 /etc/sudoers.d/vscode

RUN mkdir -p /run/sshd

WORKDIR /workspaces

USER vscode