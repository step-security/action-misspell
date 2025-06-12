FROM golang:1.23-alpine@sha256:309d7f021043f8477f85b20d7fac1eb57e30a117b1192236dbfd47665c9811ac

ENV REVIEWDOG_VERSION=v0.20.3

RUN apk add --no-cache \
        ca-certificates \
        git \
        wget \
        curl \
        bash

RUN git clone --depth 1 --branch ${REVIEWDOG_VERSION} https://github.com/reviewdog/reviewdog.git /reviewdog \
    && cd /reviewdog \
    && go mod edit -require=golang.org/x/crypto@v0.35.0 \
    && go mod tidy \
    && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o reviewdog ./cmd/reviewdog \
    && mv reviewdog /usr/local/bin/reviewdog \
    && cd / \
    && rm -rf /reviewdog /go/pkg /root/.cache /root/go

RUN wget -O - -q https://raw.githubusercontent.com/golangci/misspell/master/install-misspell.sh | sh -s -- -b /usr/local/bin/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
