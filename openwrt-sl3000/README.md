# OpenWrt 固件编译配置 - SL-3000 (MT7981 eMMC)

本配置用于为 **SL-3000** 路由器编译 OpenWrt 固件，专为 eMMC 存储优化，内置 Docker、OpenClash、Lucky 等常用插件。

## 设备规格

| 项目 | 规格 |
|------|------|
| CPU | MediaTek MT7981B (ARM Cortex-A53, Dual Core 1.3GHz) |
| WiFi | MT7976CN (WiFi 6, AX3000) |
| 交换机 | MT7531AE (Gigabit) |
| RAM | 1GB DDR4 |
| 存储 | 128GB eMMC |
| 架构 | ARMv8 (aarch64_cortex-a53) |
| USB | 1x USB 3.0 |

## 内置插件

### 核心功能
| 插件 | 功能说明 |
|------|----------|
| **Docker** | 完整容器支持 (docker + docker-compose + containerd) |
| **OpenClash** | Clash 代理客户端，支持 SS/SSR/Vmess/Trojan/Hysteria 等 |
| **Lucky (大吉)** | 动态域名(DDNS)/反向代理/网络唤醒/计划任务 |

### LuCI 应用
- `luci-app-firewall` - 防火墙管理
- `luci-app-ddns` - 动态域名
- `luci-app-upnp` - UPnP 端口自动映射
- `luci-app-samba4` - 文件共享
- `luci-app-wol` - 网络唤醒
- `luci-app-zerotier` - 虚拟局域网
- `luci-app-ttyd` - Web 终端
- `luci-app-filetransfer` - 文件传输
- `luci-app-autoreboot` - 定时重启
- `luci-app-ramfree` - 释放内存
- `luci-app-wrtbwmon` - 实时流量监控
- `luci-app-nlbwmon` - 带宽监控
- `luci-app-sqm` - 流量整形 (QoS)
- `luci-app-diskman` - 磁盘管理
- `luci-app-vlmcsd` - KMS 激活服务器

### 主题
- `luci-theme-argon` - Argon 主题（默认）
- `luci-theme-bootstrap` - Bootstrap 主题

## 快速开始

### 方法一：GitHub Actions 自动编译（推荐）

1. **Fork 本仓库**
   - 点击右上角的 "Fork" 按钮

2. **启动编译**
   - 进入 Actions 页面
   - 选择 "Build OpenWrt for SL-3000"
   - 点击 "Run workflow"

3. **下载固件**
   - 编译完成后（约 1-2 小时）
   - 在 Releases 页面下载固件

### 方法二：本地 Docker 编译

```bash
# 1. 克隆仓库
git clone https://github.com/yourusername/openwrt-sl3000.git
cd openwrt-sl3000

# 2. 使用 Docker 编译
docker build -f Dockerfile.simple -t openwrt-sl3000 .
docker run -v $(pwd)/output:/workdir/openwrt/bin/targets openwrt-sl3000

# 或在 Docker 容器内手动编译
docker run -it openwrt-sl3000 /bin/bash
# 然后执行 /home/builder/build.sh
```

### 方法三：本地 Ubuntu 编译

```bash
# 1. 安装依赖
sudo apt update
sudo apt install -y build-essential clang flex bison g++ gawk \
    gcc-multilib g++-multilib gettext git libncurses5-dev \
    libssl-dev python3-distutils rsync unzip zlib1g-dev \
    file wget curl time

# 2. 克隆源码
git clone --depth 1 -b openwrt-24.10 https://github.com/immortalwrt/immortalwrt.git
cd immortalwrt

# 3. 复制配置
cp /path/to/.config .config
cp /path/to/feeds.conf feeds.conf

# 4. 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 5. 配置
make defconfig

# 6. 下载包
make download -j$(nproc)

# 7. 编译
make -j$(nproc) V=s
```

## 刷机指南

### 准备工作

1. **下载所需文件**
   - 固件：`immortalwrt-mediatek-filogic-sl-3000-ext4-sysupgrade.bin`
   - FIP 文件：`spinor_fip_by.bin`（用于恢复 SPI-NOR 访问）

2. **进入恢复模式**
   - 断电
   - 按住 Reset 按钮
   - 通电，等待指示灯闪烁后松开
   - 电脑设置静态 IP: `192.168.1.2/24`

### 首次刷机（从原厂固件）

#### 步骤 1：进入 U-Boot 恢复界面
1. 断电，按住 Reset 按钮
2. 通电，等待指示灯闪烁后松开 Reset
3. 浏览器访问 `http://192.168.1.1`

#### 步骤 2：刷入 FIP（重要！）
```bash
# 通过 SSH 登录（刷入临时固件后）
ssh root@192.168.1.1

# 上传 spinor_fip_by.bin 到 /tmp
# 刷入 FIP
mtd write /tmp/spinor_fip_by.bin FIP
```

#### 步骤 3：刷入 GPT 分区固件
1. 重新进入 U-Boot 恢复界面
2. 选择固件文件：`immortalwrt-mediatek-filogic-sl-3000-ext4-sysupgrade.bin`
3. 点击刷写，等待完成（约 3-5 分钟）

### 系统升级

通过 LuCI 界面：
1. 系统 → 备份/升级
2. 选择固件文件
3. 刷写固件（可保留配置）

通过命令行：
```bash
# 上传固件到 /tmp
sysupgrade -F /tmp/immortalwrt-*.bin

# 保留配置升级
sysupgrade -F -c /tmp/immortalwrt-*.bin
```

## 默认配置

| 项目 | 默认值 |
|------|--------|
| IP 地址 | 192.168.1.1 |
| 用户名 | root |
| 密码 | （首次登录设置） |
| WiFi SSID 2.4G | OpenWrt-2.4G |
| WiFi SSID 5G | OpenWrt-5G |
| WiFi 密码 | 无 |
| SSH 端口 | 22 |
| Lucky 端口 | 16601 |

## 插件使用说明

### OpenClash

1. **首次启动**
   - 服务 → OpenClash
   - 全局设置 → 内核编译版本 → 选择 `linux-armv8`

2. **下载内核**
   - 版本更新 → 下载 Dev 内核
   - 如果下载失败，手动下载对应架构内核上传

3. **添加订阅**
   - 配置文件订阅 → 添加
   - 输入配置文件名和订阅地址
   - 保存并启动

### Lucky (大吉)

1. **访问界面**
   - 服务 → Lucky → 打开 Lucky
   - 或直接访问 `http://192.168.1.1:16601`

2. **初始设置**
   - 首次使用需要设置管理员账号

3. **主要功能**
   - **动态域名**：支持阿里云、腾讯云、Cloudflare 等
   - **反向代理**：HTTP/HTTPS 反向代理
   - **网络唤醒**：Wake on LAN
   - **计划任务**：定时执行脚本

### Docker

1. **启用服务**
   - Docker → 概览 → 启用 Docker

2. **使用示例**
```bash
# SSH 登录后
# 运行 Nginx
docker run -d --name nginx -p 8080:80 nginx

# 运行 Ubuntu
docker run -d --name ubuntu --restart=always \
  -v /opt/ubuntu:/root \
  ubuntu:22.04 tail -f /dev/null
```

3. **数据持久化**
   - eMMC 有 128GB 空间
   - 建议将 Docker 数据挂载到 `/opt` 目录

## 常见问题

### Q: WiFi 无法启动或没有信号
**A**: SL-3000 需要从 factory 分区读取 WiFi 校准数据：
```bash
# 检查 factory 分区是否存在
hexdump -C /dev/mtd2 | head

# 如果为空，可能需要从原厂固件备份恢复
# 或使用通用的 MT7981 固件文件
```

### Q: 编译失败，提示内存不足
**A**: 
```bash
# 增加交换空间
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 或减少并行编译任务
make -j1 V=s
```

### Q: 下载包失败
**A**: 使用镜像源：
```bash
# 修改 feeds.conf
sed -i 's|github.com|ghproxy.com/https://github.com|g' feeds.conf
./scripts/feeds update -a
```

### Q: eMMC 分区大小
**A**: 本配置已设置 rootfs 分区为 2048MB，如需调整：
```bash
make menuconfig
# Target Images → Root filesystem partition size
```

### Q: Docker 容器无法访问网络
**A**: 检查防火墙设置：
```bash
# 允许 Docker 转发
iptables -A FORWARD -i docker0 -j ACCEPT
iptables -A FORWARD -o docker0 -j ACCEPT
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `.config` | OpenWrt 编译配置 |
| `feeds.conf` | 软件源配置 |
| `.github/workflows/build-sl3000.yml` | GitHub Actions 工作流 |
| `Dockerfile` | Docker 构建环境 |
| `Dockerfile.simple` | 简化版 Docker 配置 |
| `build.sh` | 自动编译脚本 |
| `manual-build.sh` | 手动编译脚本 |

## 参考链接

- [ImmortalWrt 官方源码](https://github.com/immortalwrt/immortalwrt)
- [ImmortalWrt-mt798x 项目](https://github.com/hanwckf/immortalwrt-mt798x)
- [OpenClash 项目](https://github.com/vernesong/OpenClash)
- [Lucky 官方文档](https://lucky666.cn)
- [恩山论坛 SL-3000 讨论](https://www.right.com.cn/FORUM/thread-8418367-1-1.html)
- [恩山论坛 SL-3000 固件分享](https://www.right.com.cn/FORUM/thread-8418797-1-1.html)

## 许可证

本配置文件遵循 GPL-2.0 许可证。

## 免责声明

本固件仅供学习和研究使用，使用本固件造成的任何设备损坏或数据丢失，作者不承担责任。刷机有风险，操作需谨慎！
