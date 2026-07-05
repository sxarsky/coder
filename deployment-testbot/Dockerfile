# Multi-stage build for Coder from source (no-embed build).
# - No "slim" tag: server subcommand is fully enabled.
# - No "embed" tag: site/ frontend is NOT required; site package returns a
#   minimal in-memory FS (one index.html), which is fine for API testing.
# - ts_omit_* tags reduce binary size by dropping unused Tailscale AWS/bird/etc code.
# Stage 1: compile the Go binary.
# Stage 2: runtime image (alpine + terraform, matching scripts/Dockerfile.base).

# ---- build stage ----
FROM golang:1.26-alpine AS builder

RUN apk add --no-cache git bash curl

WORKDIR /src

# Copy go module files first for layer-cache efficiency.
COPY go.mod go.sum ./
RUN go mod download

# Copy source (site/ is excluded via Dockerfile.dockerignore — not needed
# without the embed tag).
COPY . .

# Build the coder server binary without embedding the frontend.
# Using enterprise/cmd/coder (same entry point as release builds).
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build \
      -tags "ts_omit_aws,ts_omit_bird,ts_omit_tap,ts_omit_kube" \
      -ldflags "-s -w -X 'github.com/coder/coder/v2/buildinfo.tag=testbot'" \
      -o /coder \
      ./enterprise/cmd/coder

# ---- runtime stage ----
FROM alpine:3.23.3

RUN apk add --no-cache \
        curl \
        wget \
        bash \
        git \
        openssl \
        openssh-client \
        tzdata && \
    addgroup -g 1000 coder && \
    adduser -D -s /bin/bash -h /home/coder -u 1000 -G coder coder

# Install Terraform (required by coder server for workspace provisioning)
RUN ARCH="$(arch)"; \
    if [ "${ARCH}" = "x86_64" ]; then ARCH="amd64"; \
    elif [ "${ARCH}" = "aarch64" ]; then ARCH="arm64"; \
    fi; \
    wget -O /tmp/terraform.zip \
      "https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_${ARCH}.zip" && \
    busybox unzip /tmp/terraform.zip -d /usr/local/bin && \
    rm -f /tmp/terraform.zip && \
    chmod +x /usr/local/bin/terraform

COPY --from=builder --chown=1000:1000 --chmod=755 /coder /opt/coder

USER 1000:1000
ENV HOME=/home/coder
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt
WORKDIR /home/coder

ENTRYPOINT ["/opt/coder", "server"]
