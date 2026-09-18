#############################
#     设置公共的变量         #
#############################
ARG BASE_IMAGE_TAG=resolute
FROM ubuntu:${BASE_IMAGE_TAG}

# 作者描述信息
LABEL org.opencontainers.image.authors="iflyelf" \
      org.opencontainers.image.vendor="iflyelf" \
      org.opencontainers.image.description="Ubuntu Lite - 精简版基础镜像(无 Go / Node.js / Python 环境)"

ARG TARGETARCH
ARG TARGETVARIANT

# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=zh_CN.UTF-8
ENV LANG=$LANG

# 镜像变量
ARG DOCKER_IMAGE=iflyelf/ubuntu
ENV DOCKER_IMAGE=$DOCKER_IMAGE
ARG DOCKER_IMAGE_OS=ubuntu
ENV DOCKER_IMAGE_OS=$DOCKER_IMAGE_OS
ARG DOCKER_IMAGE_TAG=lite
ENV DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG

# 环境设置
ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND=$DEBIAN_FRONTEND

ARG PKG_DEPS="\
    zsh \
    bash \
    bash-doc \
    bash-completion \
    ipset \
    bind9-dnsutils \
    iproute2 \
    nftables \
    socat \
    psmisc \
    procps \
    sysstat \
    tcpdump \
    telnet \
    lsof \
    iftop \
    htop \
    jq \
    curl \
    wget \
    axel \
    git \
    vim \
    tree \
    unzip \
    zip \
    tar \
    lrzsz \
    openssl \
    locate \
    ca-certificates \
    locales \
    tzdata \
    tini \
    sshpass \
    iputils-ping"
ENV PKG_DEPS=$PKG_DEPS

# ***** 安装依赖 *****
RUN set -eux && \
   # 更新源地址
   sed -i 's@URIs: http://[a-z.]*\.ubuntu\.com/ubuntu/@URIs: https://mirrors.aliyun.com/ubuntu/@g' /etc/apt/sources.list.d/ubuntu.sources && \
   # 解决证书认证失败问题
   touch /etc/apt/apt.conf.d/99verify-peer.conf && echo >>/etc/apt/apt.conf.d/99verify-peer.conf "Acquire { https::Verify-Peer false }" && \
   # 默认不安装 recommends/suggests, 精简体积
   printf 'APT::Install-Recommends "false";\nAPT::Install-Suggests "false";\n' > /etc/apt/apt.conf.d/99no-recommends && \
   # 更新系统软件
   DEBIAN_FRONTEND=noninteractive apt update -qqy && apt upgrade -qqy && \
   # 安装依赖包(--no-install-recommends 只装必需依赖)
   DEBIAN_FRONTEND=noninteractive apt install -qqy --no-install-recommends $PKG_DEPS --option=Dpkg::Options::=--force-confdef && \
   # 验证依赖包是否真正安装成功(逐个检查 dpkg 状态, 缺失则构建失败)
   for pkg in $PKG_DEPS; do \
       if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then \
           echo "ERROR: 依赖包未成功安装: $pkg" >&2 && exit 1; \
       fi; \
   done && \
   echo "所有依赖包验证通过" && \
   DEBIAN_FRONTEND=noninteractive apt -qqy autoremove --purge && \
   DEBIAN_FRONTEND=noninteractive apt -qqy autoclean && \
   # 更新时区
   ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
   # 更新时间
   echo ${TZ} > /etc/timezone && \
   # 更改为zsh
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true && \
   sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd && \
   # 删除 oh-my-zsh 的 git 历史(安装脚本会 clone 完整仓库, 无需保留)
   rm -rf /root/.oh-my-zsh/.git /root/.oh-my-zsh/.github && \
   # vim 默认配置文件存在时才关闭 mouse(不同版本路径不同, 用 find 定位)
   find /usr/share/vim -name defaults.vim -exec sed -i -e 's/mouse=/mouse-=/g' {} + && \
   locale-gen zh_CN.UTF-8 && localedef -f UTF-8 -i zh_CN zh_CN.UTF-8 && locale-gen && \
   # ***** 清理冗余文件, 进一步压缩体积 *****
   # 删除 man/info 文档
   rm -rf /usr/share/man/* /usr/share/info/* /usr/share/doc/*/changelog.* && \
   # 仅保留 zh_CN 与 en 语言包, 删除其它 locale
   find /usr/share/locale -mindepth 1 -maxdepth 1 -type d ! -name 'zh_CN*' ! -name 'en*' ! -name 'C*' ! -name 'locale.alias' -exec rm -rf {} + && \
   # 清理 apt 索引/缓存/日志/临时文件
   rm -rf /var/lib/apt/lists/* /var/cache/apt/* /var/log/* /tmp/* /var/tmp/*

# 使用 tini 作为 init, 优雅处理信号与僵尸进程
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/bin/zsh"]
