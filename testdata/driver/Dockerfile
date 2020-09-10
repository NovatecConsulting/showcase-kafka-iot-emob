FROM golang:1.15.2-alpine as builder

RUN apk add --no-cache gcc g++ \
    && rm -rf /var/cache/apk/*

WORKDIR /workspace
COPY . .
RUN go build -tags 'netgo osusergo' -ldflags "-linkmode external -extldflags -static"

FROM alpine:3.12.0
RUN apk add --no-cache ca-certificates \
    && rm -rf /var/cache/apk/*
COPY --from=builder /workspace/driver /driver
CMD ["/driver"]