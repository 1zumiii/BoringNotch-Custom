<h1 align="center">Boring Notch · Izumi Edition ✨</h1>

<p align="center">
  <a href="https://github.com/TheBoredTeam/boring.notch">Boring Notch</a> 的个人魔改版：把刘海做成通知中心、系统仪表盘和音频混音台。<br>
  上游原版的说明保留在 <a href="README.upstream.md">README.upstream.md</a>。
</p>

---

## 这是什么

这是 [TheBoredTeam/boring.notch](https://github.com/TheBoredTeam/boring.notch) 的 fork，基于上游 `v2.8-rc.2`，在其上加了不少自用功能，修了一批 macOS 26/27 上遇到的问题。

- 默认分支是 `custom-main`，**同步只走一个方向：上游 → 本 fork**。不会向上游推送或提 PR。
- 软件内更新（Sparkle）被**有意关闭**，避免点到更新后官方版本覆盖这些改动；“关于”页显示 **Izumi Edition ✨ 1.1.0**。要跟进上游，请把上游合并进 `custom-main` 再自己编译。
- 主要在 macOS 27 上日常使用和测试；系统要求沿用上游（macOS 14+），但下面的部分功能需要更新的系统，见各功能说明。

## 新增功能

### 🔔 通知接管

把系统通知显示在刘海里，并且可以让系统横幅完全不出现。

- **在刘海里显示通知**：读取通知中心的横幅，挪到屏幕外并在刘海里重新显示（需要辅助功能权限）。
- **自动展开**：通知到达时刘海自动展开，不用把鼠标移上去。
- **停留时间**：可调（2–30 秒），到点自动收回。
- **按应用过滤**：全部应用，或只显示你选的应用。
- **读取系统数据库**（需要完全磁盘访问权限）：直接读通知中心的数据库，这样可以在系统设置里把某个应用的横幅关掉，屏幕上不再闪一下，通知仍然出现在刘海。
- **立即显示来源应用**：横幅关闭的应用，通知一到就先在刘海里显示应用图标，约 5 秒后系统把正文写进数据库，再原位补上文字。早期信号来自系统日志里 usernoted 的“通知已入库”记录。
- **时间敏感通知高亮**：数据库里带“时间敏感/紧急”级别的通知，会有两侧和底边的旋转彩虹描边，停留时间翻倍，也不会被普通通知顶掉（被扣住的通知等它收起后接着显示）。
- **服务状态面板**：通知设置页顶部显示后台助手、横幅读取、数据库读取、早期信号各自是否在运行、最近一次事件的时间，以及一个“重启服务”按钮。通知不出现时先看这里。
- **测试通知**：下拉框选类型（真实系统通知 / 普通 / 时间敏感），一键发送。
- 图标解析更完整：能找到 `/System/Applications/Utilities` 里的应用，应用名到 Bundle ID 的映射在后台建索引，不再卡 1–2 秒。

### 📊 仪表盘（Dashboard）标签页

- 网格布局，可在设置里自由调整每张卡片的位置和大小（如 2×3、1×2）。
- **Claude / Codex 用量**卡片：读取 RunCat 集成脚本写出的用量快照（`~/Library/Application Support/RunCatIntegrations/claude-usage.json`、`~/.codex/runcat-usage.json`）。
- **存储空间**卡片：环形图加文字，间距均分。
- 所有卡片共用一套卡片/仪表组件，风格统一。

### 🎚️ 混音器（Mixer）标签页

类似 SoundSource 的逐应用音量控制，基于 Core Audio 进程 tap：

- 每个正在发声的应用单独调音量、静音、独奏。
- 声道平衡 / 单声道。
- 输出设备路由（按应用选输出设备）。
- 实时电平表（只在页面可见时才计算，空闲时开销约 0.2–0.3% 单核）。
- 没有应用发声时显示居中的单行提示。
- 需要“系统音频录制”类权限，首次使用时按提示授权。

### 📋 剪贴板临时区

Shelf（文件架）标签页里加了一块剪贴板临时区：纵向单行列表、超出一行用省略号、一键清空，设置里可整体开关。

### 🔋 电池与充电提醒

- 自定义低电量提醒：可选多个阈值（默认 20% / 10% / 5%），设置页里勾选，提醒不会反复抽搐。
- 充电提示重做：居中的圆角板，拔掉电源时只提示一次，状态文字有中文翻译。

### 🌈 音乐波形

- 新增**炫彩波形**选项，用 Core Animation 做循环动画，几乎不占 CPU。
- 炫彩速度滑块，拖到 0 可让颜色静止。
- 音频电平按像素量化后再发布，没有消费者时不做 FFT。

## 修复与优化

- **macOS 27 通知接管失效**：新系统把所有横幅放进一个全屏窗口，原来的“窗口太高就忽略”判断反而把横幅也过滤掉了。现在按横幅元素识别，并把侧边通知栏里的条目与实时横幅区分开，打开通知栏不再被误挪、也不再来回弹。
- **被挤掉的占位符吞掉自己的正文**：两条通知的占位符相继出现时，先出现的那条等正文到了会被当作重复丢弃，已修复。
- **刘海底部漏缝**（macOS 27 菜单栏比刘海高 1–2 pt）：刘海高度跟随菜单栏。
- **OSD 设置页没有标题**：之前会沿用上一个页面的标题，现已补上。
- **日历**：打开刘海时事件列表只加载一次，加载过程用骨架屏占位，设置时间不会被提前打断。
- **通知相关**：自动展开的通知不再被“悬停”误判而一直不收；刘海自动关闭时通知视图不再提前消失。
- **启动清理**：助手进程启动时清掉上次被强杀留下的 `log stream` 孤儿进程。
- **简体中文**：补全了绝大部分之前未翻译的字符串，本 fork 新增的界面也都有中文。

## 编译与安装

需要 macOS 15.6+ 和 Xcode 26+。

```bash
git clone https://github.com/1zumiii/BoringNotch-Custom.git
cd BoringNotch-Custom
git checkout custom-main
open boringNotch.xcodeproj
```

在 Xcode 里直接运行即可。想像日常安装那样**保留辅助功能 / 完全磁盘访问授权**，需要在每次构建后用固定的代码签名要求重签（否则授权会随构建丢失）：

```bash
xcodebuild -project boringNotch.xcodeproj -scheme boringNotch -configuration Release \
  -derivedDataPath build CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build

codesign --force --sign - --preserve-metadata=entitlements,flags,runtime \
  -r='designated => identifier "theboringteam.boringnotch"' \
  "build/Build/Products/Release/Boring Notch.app"
```

注意只给最外层 App 签名，不要加 `--deep`，否则 XPC 助手的签名会被破坏，通知接管会提示没有辅助功能权限。

## 需要的权限

| 权限 | 用途 |
| --- | --- |
| 辅助功能 | 读取并挪走系统通知横幅 |
| 完全磁盘访问 | 读取通知数据库（可关横幅、立即显示来源应用、时间敏感判断） |
| 系统音频录制 | 混音器的逐应用音量与电平 |
| 日历 / 提醒事项 / 相机等 | 沿用上游功能 |

## 目录里的自定义部分

| 位置 | 内容 |
| --- | --- |
| `boringNotch/managers/SystemNotificationManager.swift` | 通知展示、队列、占位符、优先级 |
| `boringNotch/managers/NotificationDatabaseWatcher.swift` | 读取通知数据库 |
| `BoringNotchXPCHelper/NotificationWatcher.swift`、`EarlyNotificationSource.swift` | 横幅读取、早期信号（在 XPC 助手里运行） |
| `boringNotch/components/Dashboard/`、`components/Usage/` | 仪表盘与用量 |
| `boringNotch/components/Mixer/`、`managers/AudioCaptureManager.swift` | 混音器与音频采集 |
| `boringNotch/models/BatteryAlertTracker.swift` | 电量提醒 |
| `boringNotch/CustomBuild.swift` | 关闭更新、自定义版本号 |

## 致谢与许可

- 上游项目 [Boring Notch](https://github.com/TheBoredTeam/boring.notch) 及其贡献者，本 fork 沿用其许可证（见 [LICENSE](LICENSE) 和 [THIRD_PARTY_LICENSES](THIRD_PARTY_LICENSES)）。
- [MediaRemoteAdapter](https://github.com/ungive/mediaremote-adapter)、[NotchDrop](https://github.com/Lakr233/NotchDrop) 等上游依赖的作者。
- 图标：[@maxtron95](https://github.com/maxtron95)。
