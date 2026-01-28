# SL-3000 OpenWrt 固件编译指南

## 目录

1. [快速开始](#快速开始)
2. [编译方法](#编译方法)
3. [刷机教程](#刷机教程)
4. [故障排除](#故障排除)

---

## 快速开始

### 推荐方式：GitHub Actions 自动编译（无需本地环境）

1. **Fork 本仓库到你的 GitHub 账号**
   ```
   点击页面右上角的 "Fork" 按钮
   ```

2. **启动编译**
   - 进入你 Fork 的仓库
   - 点击 "Actions" 标签
   - 选择 "Build OpenWrt for SL-3000"
   - 点击 "Run workflow"
   - 等待 1-2 小时

3. **下载固件**
   - 编译完成后，点击 "Releases"
   - 下载固件文件

---

## 编译方法

### 方法一：Docker 编译（推荐有 Docker 环境的用户）

```bash
# 1. 进入项目目录
cd openwrt-sl3000

# 2. 构建 Docker 镜像
docker build -f Dockerfile.simple -t openwrt-sl3000-builder .

# 3. 运行编译容器
docker run -v $(pwd)/output:/workdir/openwrt/bin/targets openwrt-sl3000-builder

# 4. 等待编译完成
# 固件将保存在 ./output/mediatek/filogic/ 目录
```

或使用 docker-compose：
```bash
docker-compose up --build
```

### 方法二：本地 Ubuntu/Debian 编译

```bash
# 1. 运行快速编译脚本
./quick-build.sh

# 或使用多线程编译
./quick-build.sh -j4

# 2. 仅下载包（不编译）
./quick-build.sh -d

# 3. 清理后重新编译
./quick-build.sh -c
```

### 方法三：手动逐步编译

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
cp /path/to/openwrt-sl3000/.config .config
cp /path/to/openwrt-sl3000/feeds.conf feeds.conf

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

---

## 刷机教程

### 准备工作

- 下载固件文件
- 下载 FIP 文件（`spinor_fip_by.bin`）
- 网线连接电脑和路由器
- 设置电脑静态 IP: `192.168.1.2/24`

### 首次刷机（从原厂固件）

#### 步骤 1：进入 U-Boot 恢复模式

1. 路由器断电
2. 按住 Reset 按钮
3. 通电，等待指示灯闪烁
4. 松开 Reset 按钮
5. 浏览器访问 `http://192.168.1.1`

#### 步骤 2：刷入临时固件

1. 在 U-Boot 界面选择固件文件
2. 上传并刷入（使用 ext4 格式固件）
3. 等待重启

#### 步骤 3：刷入 FIP（关键步骤）

```bash
# SSH 登录路由器
ssh root@192.168.1.1

# 上传 FIP 文件到 /tmp
# 刷入 FIP
mtd write /tmp/spinor_fip_by.bin FIP

# 重启
reboot
```

或使用辅助脚本：
```bash
./flash-helper.sh flash-fip --fip-file spinor_fip_by.bin
```

#### 步骤 4：刷入正式固件

1. 重新进入 U-Boot 恢复模式
2. 选择固件：`immortalwrt-*-sl-3000-ext4-sysupgrade.bin`
3. 刷写并等待完成

或使用辅助脚本：
```bash
./flash-helper.sh flash-fw -f immortalwrt-*.bin
```

### 系统升级（已有 OpenWrt）

```bash
# 通过 LuCI
# 系统 → 备份/升级 → 刷写固件

# 或通过命令行
sysupgrade -F /tmp/firmware.bin

# 保留配置升级
sysupgrade -F -c /tmp/firmware.bin
```

---

## 故障排除

### 编译问题

#### 错误：内存不足
```bash
# 增加交换空间
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 或减少并行任务
make -j1 V=s
```

#### 错误：下载失败
```bash
# 使用镜像源
sed -i 's|github.com|ghproxy.com/https://github.com|g' feeds.conf
./scripts/feeds update -a
```

#### 错误：权限不足
```bash
# 确保不是 root 用户
# 确保有 sudo 权限
sudo usermod -aG sudo $USER
```

### 刷机问题

#### WiFi 无法启动
- 确保已正确刷入 FIP
- 检查 factory 分区是否存在
- 可能需要从原厂固件提取 WiFi 校准数据

#### 无法进入 U-Boot
- 确保正确按住 Reset 按钮
- 尝试不同的按键时间
- 检查网线连接

#### 刷机后无法启动
- 尝试重新刷机
- 检查固件文件是否完整
- 尝试不同的固件格式（ext4/squashfs）

### 使用问题

#### Docker 无法启动
```bash
# 检查内核模块
lsmod | grep docker

# 手动加载模块
modprobe br_netfilter
modprobe veth

# 设置 Docker 数据目录
./flash-helper.sh setup-docker
```

#### 软件包安装失败
```bash
# 更新软件源
opkg update

# 手动安装内核模块
# 下载对应版本的 kernel_*.ipk
opkg install kernel_5.15.*_aarch64_cortex-a53.ipk
```

---

## 文件说明

| 文件 | 用途 |
|------|------|
| `.config` | OpenWrt 编译配置 |
| `feeds.conf` | 软件源配置 |
| `.github/workflows/build-sl3000.yml` | GitHub Actions 自动编译 |
| `Dockerfile` / `Dockerfile.simple` | Docker 编译环境 |
| `build.sh` | 容器内编译脚本 |
| `manual-build.sh` | 手动编译脚本 |
| `quick-build.sh` | 本地快速编译脚本 |
| `flash-helper.sh` | 刷机辅助脚本 |
| `docker-compose.yml` | Docker Compose 配置 |

---

## 参考资源

- [ImmortalWrt 官方](https://github.com/immortalwrt/immortalwrt)
- [OpenClash](https://github.com/vernesong/OpenClash)
- [Lucky](https://lucky666.cn)
- [恩山论坛 SL-3000](https://www.right.com.cn/FORUM/thread-8418367-1-1.html)

---

## 许可证

GPL-2.0
