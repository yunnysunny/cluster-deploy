FROM registry.cn-hangzhou.aliyuncs.com/whyun/base:golang-latest AS build-stage

RUN go install github.com:yunnysunny/consul-register@v0.1.0

FROM registry.cn-hangzhou.aliyuncs.com/whyun/base:hello-latest AS app-stage
ENV REGISTERED_HTTP_SERVICE_NAME hello-service
ENV REGISTERED_HTTP_SERVICE_PORT 8000
COPY --from=build-stage /root/go/bin/consul-register /bin/
COPY . /

ENTRYPOINT [ "/entrypoint.sh" ]