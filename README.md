# WiFi Hotspot Auto-Setup / WiFi 热点自动设置工具
[![PowerShell](https://img.shields.io/badge/PowerShell-5.0+-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![Windows](https://img.shields.io/badge/Windows-10+-green.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
A PowerShell script that automatically sets up WiFi hotspot with system startup task. It handles network services, creates scheduled tasks, and enables Windows Mobile Hotspot with proper error handling and logging.
一个 PowerShell 脚本，用于自动设置 WiFi 热点并创建系统启动任务。它处理网络服务、创建计划任务，并启用 Windows 移动热点，具有完善的错误处理和日志记录功能。
---
## Features / 功能特性
- ✅ **Automatic Privilege Elevation** / 自动权限提升
- ✅ **Network Service Management** / 网络服务管理
- ✅ **System Startup Task** / 系统启动任务
- ✅ **PowerShell 5.0+ Compatible** / 兼容 PowerShell 5.0+
- ✅ **Detailed Logging** / 详细日志记录
- ✅ **Error Handling & Recovery** / 错误处理与恢复
---
## Quick Start / 快速开始
### One-Click Execution / 一键执行
```powershell
# Run directly / 直接运行
irm https://get.data-seek.cn/hotspot.ps1 | iex
```
### Download & Execute / 下载后执行
```powershell
# Download the script / 下载脚本
irm https://get.data-seek.cn/hotspot.ps1 -OutFile hotspot.ps1
# Execute the script / 执行脚本
.\hotspot.ps1
```
---
## Requirements / 系统要求
- **Windows** / Windows 系统: 
  - ✅ Windows 10 (any version / 任何版本)
  - ✅ Windows 11 (any version / 任何版本)
  - ✅ Windows Server 2016 or later / Windows Server 2016 或更高版本
  - ❌ Windows 8.1 and earlier / Windows 8.1 及更早版本 (not supported / 不支持)
- **PowerShell** / PowerShell: 5.0 or later / 或更高版本
- **Administrator Privileges** / 管理员权限 (auto-requested / 自动请求)
- **Network Adapter** / 网络适配器: WiFi adapter required / 需要 WiFi 适配器
- **Mobile Hotspot Support** / 移动热点支持: Windows 10+ native feature / Windows 10+ 原生功能
---
## How It Works / 工作原理
### Architecture / 架构设计
```
User runs launcher / 用户运行启动器
    ↓
Check privileges / 检查权限
    ↓
Request elevation if needed / 必要时请求提升权限
    ↓
Download main script / 下载主脚本
    ↓
Execute with admin rights / 以管理员权限执行
    ↓
Setup network services / 设置网络服务
    ↓
Create startup task / 创建启动任务
    ↓
Enable WiFi hotspot / 启用 WiFi 热点
```
### File Structure / 文件结构
```
get.data-seek.cn/
├── hotspot.ps1          # Launcher / 启动器 (handles elevation / 处理权限提升)
└── hotspot-main.ps1     # Main Script / 主脚本 (core functionality / 核心功能)
```
---
## What It Does / 执行内容
### 1. Network Services / 网络服务
The script ensures these services are running:
脚本确保以下服务正在运行：
- **WlanSvc** - WLAN AutoConfig / WLAN 自动配置
- **NlaSvc** - Network Location Awareness / 网络位置感知
- **NetSetupSvc** - Network Setup Service / 网络设置服务
### 2. Scheduled Task / 计划任务
Creates a system startup task:
创建系统启动任务：
- **Task Name** / 任务名称: `WiFiHotspotSystemStartup`
- **Trigger** / 触发器: System startup with 20s delay / 系统启动后20秒延迟
- **Account** / 账户: SYSTEM with highest privileges / SYSTEM 最高权限
- **Action** / 操作: Execute hotspot enable script / 执行热点启用脚本
### 3. Hotspot Configuration / 热点配置
- Enables Windows Mobile Hotspot / 启用 Windows 移动热点
- Uses existing network connection / 使用现有网络连接
- Applies system default settings / 应用系统默认设置
---
## Troubleshooting / 故障排除
### Common Issues / 常见问题
#### 1. "Administrator privileges required" / "需要管理员权限"
```powershell
# Solution / 解决方案:
# Right-click PowerShell and select "Run as Administrator"
# 右键点击 PowerShell 并选择"以管理员身份运行"
```
#### 2. "Windows version does not support Mobile Hotspot" / "Windows 版本不支持移动热点"
```powershell
# Solution / 解决方案:
# Upgrade to Windows 10 or later
# 升级到 Windows 10 或更高版本
```
#### 3. "Failed to download script" / "下载脚本失败"
```powershell
# Solution / 解决方案:
# Check internet connection / 检查网络连接
# Try manual download / 尝试手动下载
irm https://get.data-seek.cn/hotspot.ps1 -OutFile hotspot.ps1
.\hotspot.ps1
```
#### 4. "Network services not ready" / "网络服务未就绪"
```powershell
# Solution / 解决方案:
# Restart WLAN service / 重启 WLAN 服务
Get-Service WlanSvc | Restart-Service
```
#### 5. "Hotspot failed to enable" / "热点启用失败"
```powershell
# Check logs / 检查日志:
Get-Content $env:TEMP\hotspot_startup.log -Tail 20
# Manual enable / 手动启用:
# Go to Settings > Network & Mobile Hotspot
# 进入 设置 > 网络和移动热点
```
### Log Files / 日志文件
- **Main Log** / 主日志: `$env:TEMP\hotspot_startup.log`
- **System Event Log** / 系统事件日志: Windows Event Viewer / Windows 事件查看器
---
## Security / 安全说明
### What the script does / 脚本执行内容
- ✅ Modifies execution policies / 修改执行策略
- ✅ Creates scheduled tasks / 创建计划任务
- ✅ Starts system services / 启动系统服务
- ✅ Enables network features / 启用网络功能
### What the script does NOT do / 脚本不执行的内容
- ❌ No data collection / 不收集数据
- ❌ No network monitoring / 不监控网络
- ❌ No personal information access / 不访问个人信息
- ❌ No internet communication (except download) / 不进行网络通信（除下载外）
---
## Version History / 版本历史
### v1.0.0 (Current / 当前版本)
- ✅ Initial release / 初始版本
- ✅ Automatic privilege elevation / 自动权限提升
- ✅ Network service management / 网络服务管理
- ✅ System startup task creation / 系统启动任务创建
- ✅ Windows 10/11 compatibility / Windows 10/11 兼容性
- ✅ Detailed logging / 详细日志记录
---
## License / 许可证
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
本项目采用 MIT 许可证 - 详情请参阅 [LICENSE](LICENSE) 文件。
---
## Support / 支持
### Getting Help / 获取帮助
- 🐛 **Issues / 问题**: [GitHub Issues](https://github.com/data-seek/Hotspot/issues)
### FAQ / 常见问题
**Q: Does this work on Windows 8.1?**
A: No, requires Windows 10 or later with Mobile Hotspot support.
问：支持 Windows 8.1 吗？
答：不支持，需要 Windows 10 或更高版本，并具备移动热点支持。
**Q: Is this safe to use on corporate networks?**
A: Yes, but check with your IT department first as it modifies system settings.
问：可以在企业网络中使用吗？
答：可以，但请先咨询 IT 部门，因为它会修改系统设置。
---
**Made with ❤️ by Data-Seek Team / 由 Data-Seek 团队用心制作**
