FROM archlinux:latest

# Update system and install the tools required by the Codespace.
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

# Create the user used by VS Code / Codespaces.
RUN useradd -m -s /bin/bash vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode && \
    chmod 440 /etc/sudoers.d/vscode

# SSH runtime directory.
RUN mkdir -p /run/sshd && \
    chmod 755 /run/sshd

WORKDIR /workspaces

USER vscode