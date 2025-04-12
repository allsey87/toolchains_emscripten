FROM debian:trixie-slim
ENV SHELL /bin/bash
ARG user_id=1000
ARG group_id=1000
ARG bazel_version=7.6.1
ARG buildifier_version=7.3.1

RUN apt-get update && apt-get install --assume-yes --no-install-recommends \
    automake \
    build-essential \
    ca-certificates \
    curl \
    git \
    libtool-bin \
    libltdl-dev \
    locales-all \
    nano \
    openssh-client \
    python3 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Configure locale
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Download Bazel
WORKDIR /tmp
RUN curl \
    --fail \
    --location \
    --remote-name \
    "https://github.com/bazelbuild/bazel/releases/download/${bazel_version}/bazel-${bazel_version}-linux-x86_64"
RUN mv "bazel-${bazel_version}-linux-x86_64" /usr/local/bin/bazel
RUN chmod +x /usr/local/bin/bazel
# Download Buildifier
RUN curl \
    --fail \
    --location \
    --remote-name \
    "https://github.com/bazelbuild/buildtools/releases/download/v${buildifier_version}/buildifier-linux-amd64"
RUN mv "buildifier-linux-amd64" /usr/local/bin/buildifier
RUN chmod +x /usr/local/bin/buildifier

# Create a developer user
ARG user_id=1000
ARG group_id=1000
RUN groupadd --gid ${group_id} developer && \
    useradd --uid ${user_id} --gid ${group_id} -m developer -s /bin/bash && \
    echo developer ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer

# Switch the developer user
USER developer

