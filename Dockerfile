FROM golang:1.25.2-alpine3.22@sha256:06cdd34bd531b810650e47762c01e025eb9b1c7eadd191553b91c9f2d549fae8

ENV REVIEWDOG_VERSION=v0.20.3 \
    MISSPELL_VERSION=v0.7.0

RUN apk add --no-cache \
        ca-certificates \
        git \
        wget \
        curl \
        bash

# Build reviewdog
RUN git clone --depth 1 --branch ${REVIEWDOG_VERSION} https://github.com/reviewdog/reviewdog.git /reviewdog \
    && cd /reviewdog \
    && go mod edit -require=golang.org/x/crypto@v0.35.0 \
    && go mod edit -require=golang.org/x/oauth2@v0.27.0 \
    && go mod tidy \
    && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o reviewdog ./cmd/reviewdog \
    && mv reviewdog /usr/local/bin/reviewdog \
    && cd / \
    && rm -rf /reviewdog /go/pkg /root/.cache /root/go

# Build misspell from source
RUN git clone --depth 1 --branch ${MISSPELL_VERSION} https://github.com/golangci/misspell.git /misspell \
    && cd /misspell \
    && go mod edit -go=1.25 \
    && go mod tidy \
    && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /usr/local/bin/misspell ./cmd/misspell \
    && cd / \
    && rm -rf /misspell /go/pkg /root/.cache /root/go

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
