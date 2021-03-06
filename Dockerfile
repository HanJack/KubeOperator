FROM golang:1.14-alpine as stage-build
LABEL stage=stage-build
WORKDIR /build/ko
ARG GOPROXY
ENV GOPROXY=$GOPROXY
ENV GO111MODULE=on
ENV GOOS=linux
ENV GOARCH=amd64
ENV CGO_ENABLED=0

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
  && apk update \
  && apk add git \
  && apk add make \
  && apk add bash
COPY go.mod go.sum ./
RUN go mod download


RUN wget https://github.com/go-bindata/go-bindata/archive/v3.1.3.zip -O /tmp/go-bindata.zip  \
    && cd /tmp \
    && unzip  /tmp/go-bindata.zip  \
    && cd /tmp/go-bindata-3.1.3 \
    && go build \
    && cd go-bindata \
    && go build \
    && cp go-bindata /go/bin

RUN export PATH=$PATH:$GOPATH/bin

COPY . .
RUN make build_server_linux

FROM alpine:3.11

COPY --from=stage-build /build/ko/dist/etc /etc/
COPY --from=stage-build /usr/local/go/lib/time/zoneinfo.zip /opt/zoneinfo.zip
ENV ZONEINFO /opt/zoneinfo.zip

COPY --from=stage-build /build/ko/dist/etc /etc/
COPY --from=stage-build /build/ko/dist/usr /usr/

RUN cd /usr/local/bin && wget https://fit2cloud-support.oss-cn-beijing.aliyuncs.com/xpack-license/validator_linux_amd64

EXPOSE 8080

CMD ["ko-server"]
