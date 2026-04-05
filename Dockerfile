FROM golang:1.26-alpine3.23@sha256:2389ebfa5b7f43eeafbd6be0c3700cc46690ef842ad962f6c5bd6be49ed82039

ENV REVIEWDOG_VERSION=v0.21.0 \
    MISSPELL_VERSION=v0.7.0

RUN apk add --no-cache \
        ca-certificates \
        git \
        wget \
        curl \
        bash \
        jq

# Build reviewdog
RUN git clone --depth 1 --branch ${REVIEWDOG_VERSION} https://github.com/reviewdog/reviewdog.git /reviewdog \
    && cd /reviewdog \
    && go mod edit -require=golang.org/x/crypto@v0.45.0 \
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
