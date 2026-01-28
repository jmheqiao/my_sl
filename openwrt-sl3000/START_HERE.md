# SL-3000 OpenWrt 固件编译套件

欢迎使用 SL-3000 OpenWrt 固件编译套件！本套件包含编译适用于 SL-3000 (MT7981) 路由器的 OpenWrt 固件所需的所有配置和脚本。

## 套件内容

```
openwrt-sl3000/
├── .config                     # OpenWrt 编译配置（含 Docker/OpenClash/Lucky）
├── .github/
│   └── workflows/
│       └── build-sl3000.yml    # GitHub Actions 自动编译配置
├── feeds.conf                  # 软件源配置
├── Dockerfile                  # Docker 编译环境
├── Dockerfile.simple           # 简化版 Docker 配置
├── docker-compose.yml          # Docker Compose 配置
├── build.sh                    # 容器内编译脚本
├── manual-build.sh             # 手动编译脚本
├── quick-build.sh              # 本地快速编译脚本
├── flash-helper.sh             # 刷机辅助脚本
├── README.md                   # 详细说明文档
├── BUILD_GUIDE.md              # 编译指南
└── START_HERE.md               # 本文件
```

## 快速开始（3 种方式）

### 方式一：GitHub Actions 自动编译（推荐，无需本地环境）

1. **Fork 本仓库到 GitHub**
   - 访问 https://github.com/yourname/openwrt-sl3000
   - 点击 "Fork" 按钮

2. **启动编译**
   - 进入 Actions 页面
   - 选择 "Build OpenWrt for SL-3000"
   - 点击 "Run workflow"

3. **下载固件**
   - 等待 1-2 小时
   - 在 Releases 页面下载

### 方式二：Docker 编译

```bash
# 构建并运行
cd openwrt-sl3000
docker build -f Dockerfile.simple -t sl3000-builder .
docker run -v $(pwd)/output:/workdir/openwrt/bin/targets sl3000-builder

# 或使用 docker-compose
docker-compose up --build
```

### 方式三：本地编译

```bash
# 运行快速编译脚本
cd openwrt-sl3000
./quick-build.sh
```

## 内置插件

| 插件 | 功能 |
|------|------|
| **Docker** | 容器支持 (docker + docker-compose) |
| **OpenClash** | Clash 代理客户端 |
| **Lucky** | DDNS/反向代理/WOL |
| **LuCI Argon** | 现代化 Web 界面 |
| **Samba4** | 文件共享 |
| **Zerotier** | 虚拟局域网 |
| **TTYD** | Web 终端 |

## 刷机简要步骤

### 首次刷机

1. **进入 U-Boot 恢复模式**
   - 断电 → 按住 Reset → 通电 → 灯闪松开

2. **刷入 FIP（关键！）**
   ```bash
   ./flash-helper.sh flash-fip --fip-file spinor_fip_by.bin
   ```

3. **刷入固件**
   ```bash
   ./flash-helper.sh flash-fw -f immortalwrt-*-sl-3000-*.bin
   ```

### 系统升级

```bash
# 保留配置升级
sysupgrade -F -c /tmp/firmware.bin
```

## 默认配置

- IP: `192.168.1.1`
- 用户名: `root`
- 密码: （首次登录设置）
- Lucky: `http://192.168.1.1:16601`

## 文档索引

| 文档 | 内容 |
|------|------|
| `README.md` | 完整说明文档 |
| `BUILD_GUIDE.md` | 详细编译指南 |
| `START_HERE.md` | 快速开始指南（本文件） |

## 获取帮助

- 查看 `BUILD_GUIDE.md` 获取详细编译说明
- 查看 `README.md` 获取完整使用说明
- 访问恩山论坛 SL-3000 讨论区

## 许可证

GPL-2.0

---

**祝使用愉快！**
