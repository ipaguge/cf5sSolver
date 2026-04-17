# 阶段1: 构建假包（不变）
FROM debian:bookworm-slim AS fake-pkgs
RUN apt-get update && apt-get install -y --no-install-recommends equivs \
    && equivs-control libgl1-mesa-dri \
    && printf 'Section: misc\nPriority: optional\nStandards-Version: 3.9.2\nPackage: libgl1-mesa-dri\nVersion: 99.0.0\nDescription: Dummy package for libgl1-mesa-dri\n' >> libgl1-mesa-dri \
    && equivs-build libgl1-mesa-dri \
    && equivs-control adwaita-icon-theme \
    && printf 'Section: misc\nPriority: optional\nStandards-Version: 3.9.2\nPackage: adwaita-icon-theme\nVersion: 99.0.0\nDescription: Dummy package for adwaita-icon-theme\n' >> adwaita-icon-theme \
    && equivs-build adwaita-icon-theme

# 阶段2: 最终运行镜像
FROM golang:1.23-bookworm

# 复制假包
COPY --from=fake-pkgs /*.deb /

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

# 安装系统 Chromium 和所有依赖（不变）
RUN dpkg -i /libgl1-mesa-dri.deb /adwaita-icon-theme.deb 2>/dev/null || true \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        chromium \
        chromium-common \
        chromium-driver \
        xvfb \
        dumb-init \
        procps \
        curl \
        xauth \
        ca-certificates \
        fonts-liberation \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libcups2 \
        libdbus-1-3 \
        libdrm2 \
        libgbm1 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxrandr2 \
        xdg-utils \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --home-dir /app --shell /bin/sh flare5sBypass \
    && mkdir -p /config \
    && chown -R flare5sBypass:flare5sBypass /config /app

VOLUME /config

# 复制预编译二进制（不变）
ARG TARGETARCH
COPY ./flare5sBypass_linux_${TARGETARCH} /app/flare5sBypass
RUN ls -la /app/flare5sBypass \
    && chmod +x /app/flare5sBypass

# 为 Chromium 崩溃报告创建目录（不变）
RUN mkdir -p "/app/.config/chromium/Crash Reports/pending" \
    && chown -R flare5sBypass:flare5sBypass /app

# ========== 关键修改：切换到 flare5sBypass 用户安装 Playwright ==========
USER flare5sBypass

# 安装 Playwright CLI（指定与你项目匹配的版本 v0.5700.1）
RUN go install github.com/playwright-community/playwright-go/cmd/playwright@v0.5700.1

# 安装 Chromium 驱动（会自动下载到 ~/.cache/ms-playwright，即 /app/.cache/ms-playwright）
RUN playwright install chromium

# 可选：验证版本
RUN playwright --version

# 设置环境变量（确保程序能找到驱动，默认路径已正确，但显式设置更可靠）
ENV PLAYWRIGHT_BROWSERS_PATH=/app/.cache/ms-playwright

# ========== 恢复 root 用户执行启动脚本写入（因为需要写 /usr/local/bin）==========
USER root

# 启动脚本（内容不变）
RUN cat > /usr/local/bin/start.sh <<'EOF' && chmod +x /usr/local/bin/start.sh
#!/bin/sh
set -e

echo "=== Starting start.sh ==="

export DISPLAY=:99
echo "DISPLAY set to $DISPLAY"

# 清理可能残留的锁文件
echo "Cleaning lock files..."
rm -f /tmp/.X99-lock
rm -f /tmp/.X11-unix/X99

# 启动 Xvfb
echo "Starting Xvfb..."
mkdir -p /tmp/.X11-unix
Xvfb :99 -screen 0 1920x1080x24 -ac >/tmp/xvfb.log 2>&1 &
XVFB_PID=$!
echo "Xvfb started with PID $XVFB_PID"

sleep 1
echo "Checking if Xvfb is running..."
if kill -0 $XVFB_PID 2>/dev/null; then
    echo "Xvfb is running."
else
    echo "ERROR: Xvfb died. Logs:"
    cat /tmp/xvfb.log
    exit 1
fi

echo "Running /app/flare5sBypass..."
exec /app/flare5sBypass
EOF

# 最终切换回 flare5sBypass 用户运行容器
USER flare5sBypass

EXPOSE 8901
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/start.sh"]