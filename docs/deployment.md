# 部署到 e445

`e445` 是 `linux/amd64` 主机。本仓库在推送到 `main` 后，会由 GitHub Actions 构建 `mi-xiaoai:latest` Docker 镜像，并将其作为 `mi-xiaoai-image` 构件保存 7 天。

## 准备配置

在服务器的部署目录中建立以下结构。配置文件和状态文件均不得提交到 Git。

```text
mi-xiaoai/
  compose.yaml
  config/
    .env
    .migpt.js
  state/
    .mi.json
    .bot.json
    app.db
```

将本地 `.env`、`.migpt.js`、`.bot.json` 和 `prisma/app.db` 复制到对应目录。创建空的 `.mi.json` 文件；容器会写入小米登录会话。SQLite 临时日志由容器自行管理，不能作为单独的 bind mount。

首次在服务器运行时，小米账号可能会要求异地登录验证。完成验证后，等待小米账号信息同步，再重启容器。若服务器环境无法完成验证，可先在本地成功登录，并将生成的 `.mi.json` 复制到服务器的 `state/.mi.json`。

## e445 透明代理直连规则

本部署固定使用 `172.31.255.0/24` Docker 子网。若 e445 启用了 Mihomo TUN 透明代理，须在 `/etc/mihomo/config.yaml` 的 `rules:` 中、`MATCH` 规则之前加入：

```yaml
- SRC-IP-CIDR,172.31.255.0/24,DIRECT
```

应用配置前先校验并重载 Mihomo：

```shell
sudo /usr/local/bin/mihomo -t -d /var/lib/mihomo -f /etc/mihomo/config.yaml
sudo systemctl restart mihomo
```

该规则按容器源 IP 匹配，保证小米云和大模型 API 请求直连，不影响主机或其他 Docker 网络的代理策略。

## 加载和启动

从成功的 GitHub Actions 运行下载 `mi-xiaoai-image` 构件并解压，得到 `mi-xiaoai-image.tar`。在服务器执行：

```shell
docker load --input mi-xiaoai-image.tar
docker compose up -d
docker compose logs -f mi-xiaoai
```

在包含 `compose.yaml` 的部署目录中执行上述命令。应用不监听 HTTP 端口；服务器需要能够访问小米云和所配置的大模型 API。
