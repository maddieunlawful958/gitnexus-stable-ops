FROM node:22-slim

LABEL maintainer="shunsuke.hayashi@miyabi-ai.jp"
LABEL description="GitNexus Stable Ops — production toolkit for running GitNexus at scale"

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    git \
    jq \
    python3 \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Install GitNexus (pin version)
ARG GITNEXUS_VERSION=1.4.6
RUN npm install -g gitnexus@${GITNEXUS_VERSION} \
    && ln -sf $(which gitnexus) /usr/local/bin/gitnexus-stable

# Install stable-ops
COPY . /opt/gitnexus-stable-ops
WORKDIR /opt/gitnexus-stable-ops
RUN make install

# Environment
ENV GITNEXUS_BIN=/usr/local/bin/gitnexus-stable
ENV REPOS_DIR=/repos
ENV NODE_OPTIONS="--max-old-space-size=8192"

# Default: run health check
CMD ["bin/gitnexus-doctor.sh"]
