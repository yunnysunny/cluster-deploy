# 构建 consul 数据中心

## 构建单数据中心

为了方便演示，这里使用 docker-compose 命令来启动一组 docker 容器

```yaml
version: '3.7'

services:
  
  consul-server-dc1-1:
    image: hashicorp/consul:1.10
    container_name: consul-server-dc1-1
    restart: always
    volumes:
     - ./server-dc1-1.json:/consul/config/server1.json:ro
    networks:
      - consul
    ports:
      - "8500:8500"
      - "8600:8600/tcp"
      - "8600:8600/udp"
    command: "agent -bootstrap-expect=3"

  consul-server-dc1-2:
    image: hashicorp/consul:1.10
    container_name: consul-server-dc1-2
    restart: always
    volumes:
     - ./server-dc1-2.json:/consul/config/server2.json:ro
    networks:
      - consul
    command: "agent -bootstrap-expect=3"

  consul-server-dc1-3:
    image: hashicorp/consul:1.10
    container_name: consul-server-dc1-3
    restart: always
    volumes:
     - ./server-dc1-3.json:/consul/config/server3.json:ro
    networks:
      - consul
    command: "agent -bootstrap-expect=3"

  consul-client:
    image: hashicorp/consul:1.10
    container_name: consul-client
    restart: always
    volumes:
     - ./client.json:/consul/config/client.json:ro
    networks:
      - consul
    command: "agent"

networks:
  consul:
    driver: bridge
```

**代码 1.1**

command 参数中没有写 `consul` 关键字，是由于 `hashicorp/consul` 镜像中会自动给补充上参数，具体可以参见其[启动脚本](https://github.com/hashicorp/docker-consul/blob/master/ubi/docker-entrypoint.sh)。如果 command 的首个单词为 `agent` ，则会自动在执行的命令中补充 `--data-dir` 参数（默认为 `/consul/data/` 目录）和 `--config-dir` 参数（默认为 `/consul/config` 目录）。`bootstrap-expect` 参数设置为 `3` 代表当前集群中 `3` 台服务器端 consul 都启动完成，才能算是集群启动成功。

所有的 consul 节点都指定了配置文件，先看 server 节点 server-dc1-1.json 文件：

```json
{
    "node_name": "consul-server-dc1-1",
    "server": true,
    "ui_config": {
        "enabled" : true
    },
    "data_dir": "/consul/data",
    "addresses": {
        "http" : "0.0.0.0"
    },
    "retry_join":[
        "consul-server-dc1-2",
        "consul-server-dc1-3"
    ],
    "encrypt": "aPuGh+5UDskRAbkLaXRzFoSOcSM+5vAK+NEYOWHJH7w="
}
```

**代码 1.2**

`server` 属性设置为 `true` 代表当前是服务节点，`retry_join` 要写集群中其他节点的地址（这里借助了 docker-compose 的内网主机名来代替 ip 地址）。`encrypt` 属性的值是通过 `consul keygen` 命令生成的。

server-dc1-2.json 和 server-dc1-3.json 和 server-dc1-1.json 不同的地方，在于 `node_name` 不同，`retry_join` 的主机名不同不同，且前两者没有配置 `ui_config` 属性。

通过在 docker-compose.yml 文件所在目录运行 `docker-compose up -d` 命令后，就启动了一个 consul 数据中心，打开浏览器 http://localhost:8500 即可通过管理界面验证是否启动成功。

## 构建多数据中心

```yml
version: '3.7'

services:

  consul-server-dc1-1:
    image: hashicorp/consul:1.10
    container_name: consul-server-dc1-1
    restart: always
    volumes:
     - ./server-dc1-1.json:/consul/config/server1.json:ro
    networks:
      - consul
    ports:
      - "8500:8500"
      - "8600:8600/tcp"
      - "8600:8600/udp"
    command: "agent -bootstrap-expect=3"

  consul-server-dc1-2:
    image: hashicorp/consul:1.10
    container_name: consul-server-dc1-2
    restart: always
    volumes:
     - ./server-dc1-2.json:/consul/config/server2.json:ro
    networks:
      - consul
    command: "agent -bootstrap-expect=3"

  consul-server-dc1-3:
    image: hashicorp/consul:1.10
    container_name: consul-server-dc1-3
    restart: always
    volumes:
     - ./server-dc1-3.json:/consul/config/server3.json:ro
    networks:
      - consul
    command: "agent -bootstrap-expect=3"
  consul-server-dc2-1:
    image: hashicorp/consul:1.10
    container_name: consul-server-dc2-1
    restart: always
    volumes:
     - ./server-dc2-1.json:/consul/config/server1.json:ro
    networks:
      - consul
    command: "agent -bootstrap-expect=3"

  consul-server-dc2-2:
    image: hashicorp/consul:1.10
    container_name: consul-server-dc2-2
    restart: always
    volumes:
     - ./server-dc2-2.json:/consul/config/server2.json:ro
    networks:
      - consul
    command: "agent -bootstrap-expect=3"

  consul-server-dc2-3:
    image: hashicorp/consul:1.10
    container_name: consul-server-dc2-3
    restart: always
    volumes:
     - ./server-dc2-3.json:/consul/config/server3.json:ro
    networks:
      - consul
    command: "agent -bootstrap-expect=3"
  consul-client-dc1:
    image: hashicorp/consul:1.10
    container_name: consul-client-dc1
    restart: always
    depends_on:
      - consul-server-dc1-1
      - consul-server-dc1-2
      - consul-server-dc1-3
    volumes:
     - ./client-dc1.json:/consul/config/client.json:ro
    networks:
      - consul
    command: "agent"
    ports:
      - "8501:8500"
  consul-client-dc2:
    image: hashicorp/consul:1.10
    container_name: consul-client-dc2
    restart: always
    depends_on:
      - consul-server-dc2-1
      - consul-server-dc2-2
      - consul-server-dc2-3
    volumes:
     - ./client-dc2.json:/consul/config/client.json:ro
    networks:
      - consul
    command: "agent"
    ports:
      - "8502:8500"
  restygate:
    image: registry.cn-hangzhou.aliyuncs.com/whyun/base:restygate-latest
    container_name: restygate
    restart: always
    depends_on:
      - consul-server-dc1-1
      - consul-server-dc1-2
      - consul-server-dc1-3
    networks:
      - consul
    ports:
      - "8800:80"
  webapp-dc1:
    image: registry.cn-hangzhou.aliyuncs.com/whyun/base:hello-service-latest
    container_name: webapp-dc1
    depends_on:
      - consul-client-dc1
    environment:
      CONSUL_ADDR: consul-client-dc1:8500
      APP_PORT: 8000
      REGISTERED_HTTP_SERVICE_PORT: 8000
      DEREGISTER_CRITICAL_SERVICE_AFTER_SECONDS: 10
    networks:
      - consul
    ports:
      - "8000:8000"
  webapp-dc2:
    image: registry.cn-hangzhou.aliyuncs.com/whyun/base:hello-service-latest
    container_name: webapp-dc2
    depends_on:
      - consul-client-dc2
    environment:
      CONSUL_ADDR: consul-client-dc2:8500
      APP_PORT: 8001
      REGISTERED_HTTP_SERVICE_PORT: 8001
      DEREGISTER_CRITICAL_SERVICE_AFTER_SECONDS: 10
    networks:
      - consul
    ports:
      - "8001:8001"
  
networks:
  consul:
    driver: bridge
```

**代码 2.1**

在增加一组 consul 集群，同时我们需要修改服务器端的配置文件，以 server-dc1-1.json 举例 

```json
{
    "node_name": "consul-server-dc1-1",
    "server": true,
    "datacenter": "dc1",
    "ui_config": {
        "enabled" : true
    },
    "data_dir": "/consul/data",
    "client_addr": "0.0.0.0",
    "retry_join":[
        "consul-server-dc1-2",
        "consul-server-dc1-3"
    ],
    "retry_join_wan":[
        "consul-server-dc2-1",
        "consul-server-dc2-2",
        "consul-server-dc2-3"
    ],
    "encrypt": "aPuGh+5UDskRAbkLaXRzFoSOcSM+5vAK+NEYOWHJH7w="
}
```

**代码 2.2**

这里增加了两个配置 `datacenter` 和 `retry_join_wan`，前者是数据中心的名字，后者是要加入的其他数据中心的节点主机名。

同样通过 `docker-compose up -d` 启动集群，再次查看 http://localhost:8500，会发现多了一个数据中心。

## 参考资料

使用 docker-compose 构建数据中心 https://learn.hashicorp.com/tutorials/consul/docker-compose-datacenter

consul 配置参数说明 https://www.consul.io/docs/agent/options



