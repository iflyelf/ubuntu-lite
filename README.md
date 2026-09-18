# ubuntu-lite

Ubuntu 精简版基础镜像。基于 [ubuntu-docker](https://github.com/iflyelf/ubuntu-docker) 裁剪而来，
**去除了 Go / Node.js / Python 等开发环境**，仅保留常用的系统运维与网络排障工具，体积更小、构建更快。

镜像标签统一为 `lite`，支持 `linux/amd64` 与 `linux/arm64` 多架构。

## 镜像获取

```bash
# Docker Hub（国外）
docker pull iflyelf/ubuntu:lite

# 华为云 SWR（国内推荐）
docker pull swr.cn-east-3.myhuaweicloud.com/danxiaonuo/ubuntu:lite
```

## 运行

```bash
docker run -it --rm iflyelf/ubuntu:lite
```

默认 shell 为 zsh（已安装 oh-my-zsh），入口使用 tini 处理信号与僵尸进程。

## 内置组件

- 时区：`Asia/Shanghai`
- 语言：`zh_CN.UTF-8`
- Shell：zsh + oh-my-zsh
- 网络与排障：iproute2、net-tools、nftables、ipset、ipvsadm、bridge-utils、openvswitch-switch、socat、tcpdump、telnet、iftop、lsof、bind9-dnsutils、iputils-ping
- 系统工具：procps、psmisc、sysstat、htop、lvm2、rsyslog、firewalld、chrony、tini
- 常用命令：curl、wget、axel、git、vim、jq、tree、zip/unzip、tar、lrzsz、openssl、sshpass、locate

完整清单见 [Dockerfile](./Dockerfile) 中的 `PKG_DEPS`。

## 自动构建

推送 `Dockerfile` 变更、手动触发（workflow_dispatch）或 Star 仓库均会触发
[GitHub Actions](./.github/workflows/docker-publish.yml) 自动构建并推送到 Docker Hub 与华为云 SWR。

同一分支仅保留最新一次构建（`concurrency` + `cancel-in-progress`），避免多架构构建并发堆积。

### 所需 Secrets

| Secret | 说明 |
| --- | --- |
| `DOCKER_USERNAME` / `DOCKER_PASSWORD` | Docker Hub 凭据 |
| `SWR_USERNAME` / `SWR_PASSWORD` | 华为云 SWR 登录凭据（`区域@AK` / 登录密钥） |
| `SWR_AK` / `SWR_SK` | 华为云账号 AK/SK，用于将 SWR 仓库设为公开（可选） |
