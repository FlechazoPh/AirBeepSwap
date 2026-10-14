# AirBeepSwap

> 🌍 **Languages:** [English](./README.md) | 简体中文

**本分支由 [Poner7](https://github.com/poner7) 维护与适配。** 仓库地址：[poner7/AirBeepSwap](https://github.com/poner7/AirBeepSwap)，基于 [FlechazoPh/AirBeepSwap](https://github.com/FlechazoPh/AirBeepSwap)。保留原作者及依赖项目的署名和许可证。

AirBeepSwap 是一款 iOS 工具，用于自定义通话录音提示音 —— 即 iOS 在通话录音开始和结束时播放的提示音。一键静音，或为每段提示音替换成你自己的音频：选择文件、查看波形与时长、试听后应用。首次修改前自动备份原始提示音，一键即可恢复。

## 功能特性

- **只安装一个 App**：AirBeepSwap 内置本地隧道，可直接在 App 内连接和断开。
- 主界面、关于页及源码中添加 Poner7 维护署名。
- 一个开关静音两段提示音（等长静音，与 AirBeep 一致）。
- **自定义提示音**：开始/结束提示音各自独立，可选择任意本地音频文件（MP3、M4A、WAV、CAF、AIFF…）。
- 自动转码为系统要求的精确格式（开始提示音：AAC 44.1 kHz 单声道 `.m4a`；结束提示音：PCM s16le 48 kHz 单声道 `.caf`），iOS 可原生播放替换后的文件。
- 波形图显示、原音与替换音频的时长对比、应用前可在 App 内试听。
- 首次修改前自动备份原始提示音文件 —— 备份会被保留且绝不会被覆盖。
- 每次写入后都会进行文件回读校验。
- 一键恢复原始提示音。
- 支持英文与简体中文界面。

## 工作原理

AirBeepSwap 通过与 [AirBeep](https://github.com/LinkPass888/AirBeep) 相同的 AirTraffic 沙盒逃逸访问系统提示音文件：

- `/var/mobile/Library/CallServices/Greetings/default/StartDisclosureWithTone.m4a`
- `/var/mobile/Library/CallServices/Greetings/default/StopDisclosure.caf`

App 将自己伪装成一台 Mac 配对主机（Bonjour/RPPairing）与本机配对。内置的 `AirBeepTunnel` 网络扩展建立本地回环通道，再由 Airlift 核心通过该通道访问设备服务、执行文件操作。只需安装 AirBeepSwap 一个 App。备份保存在应用 Documents 目录下的 `AirBeepSwapBackups` 中。

## 系统要求

- 默认 IPA 需要一台运行 **iOS/iPadOS 26.0 – 27.2 B2** 的实体 iPhone 或 iPad（源码版本检查也允许 18–25，但当前构建的最低安装版本为 26.0）。
- 付费 Apple Developer 账号，主 App 和内置扩展的签名描述文件都需允许网络扩展。
- 先完成配对，再在 App 内连接内置隧道并允许 iOS 添加 VPN 配置，无需另装 LocalDevVPN。
- 本地构建需 Xcode 27 或更高版本。
- 仓库提供的 GitHub Actions 工作流可在云端构建 unsigned IPA。

### iPhone 18 Pro Max / iOS 27.0.1

版本检查允许 iOS 27.0.1，程序没有 iPhone 机型白名单。1.0.2 修复了内置 Airlift 库缺少文件访问函数的问题，并在首次安装时显示配对设置；1.1.0 加入内置本地隧道。构建的最低安装版本仍为 iOS 26.0，因此 iOS 27.0.1 满足安装要求。

2026 年 10 月 14 日，主 App 和内置扩展已使用有效的开发证书及包含网络扩展权限的描述文件签名，并在运行 iOS 27.0.1 的实体 iPhone 18 Pro Max 上安装、启动成功。系统版本检查、数据包回环测试、归档校验和模拟器启动也已通过。实际配对、隧道连接和系统提示音读写仍需真机验证。

> AirBeepSwap 依赖非公开的系统行为，不同 iOS 版本之间兼容性可能发生变化。

## 使用

1. 安装并打开 App。
2. 在 **Airlift 设置**中开始配对，前往“设置 › 隐私与安全性 › 开发者模式”确认 PIN。
3. 返回 App，点击**连接隧道**，允许 iOS 添加 VPN 配置，再点击**检查并进入**。
4. 使用静音开关，或为每段提示音选择自定义音频并点击**替换为此音频**。操作结束后，可在 Airlift 设置中断开隧道。

## 构建

打开 `airbeepswap.xcodeproj`，选择 `airbeepswap` scheme，为 `airbeepswap` 和 `AirBeepTunnel` 两个 target 设置签名，然后构建到实体设备。

如需构建 unsigned IPA，请在 GitHub Actions 中运行 `Release unsigned IPA` 工作流。成品文件名为 `airbeepswap-v<version>-unsigned.ipa`。

本地无需签名团队即可运行 `bash scripts/build-unsigned-ipa.sh`，脚本检查系统版本边界和 Airlift 集成后，将 IPA 输出到 `build/unsigned/`。安装前需使用你自己的证书签名。如需重新编译原生核心，请安装 Rust 并先运行 `bash scripts/build-airlift-xcframework.sh`。

### 单 App 版本签名

1. **两个 target** 都选择你的付费开发者团队。
2. 将项目级构建设置 `AIRBEEP_BUNDLE_IDENTIFIER` 改成你自己的唯一 App ID，例如 `com.yourname.airbeep`；扩展 ID 会自动变为 `com.yourname.airbeep.tunnel`。
3. 两个 App ID 都启用 **Network Extensions / Packet Tunnel**，主 App 还需启用 **Personal VPN**。更新对应描述文件，或让 Xcode 自动签名处理。
4. 使用 IPA 签名工具时，保留 `PlugIns/AirBeepTunnel.appex`，用同一团队下各自对应的描述文件给扩展和主 App 签名。删除扩展或去掉相关权限会导致隧道无法启动。

unsigned 归档和模拟器启动无法确认 VPN 授权或设备服务连接。签名安装后，需在实体 iPhone 上验证连接、提示音备份/替换以及恢复。

## 法律声明

移除或替换提示音后，对方将不再收到"通话正在被录音"的告知。许多国家和地区法律要求录音前告知所有参与方。请仅在你自己的设备上、且在法律允许的情况下使用本应用，遵守适用法律是你的责任。

## 致谢

- [Poner7](https://github.com/poner7) —— 本分支维护者；iPhone 18 Pro Max / iOS 27.0.1 适配、内置本地隧道集成及构建修复。
- [AirBeepSwap](https://github.com/FlechazoPh/AirBeepSwap)（FlechazoPh）—— 本分支所基于的原始自定义提示音 App。
- [AirBeep](https://github.com/LinkPass888/AirBeep)（LinkPass888，GPLv3）—— 本项目基于该 iOS App 修改。
- [airlift](https://github.com/0xjohnnydev/airlift)（0xjohnnydev，MIT）—— AirTraffic 沙盒逃逸研究。
- [AirliftSilence](https://github.com/YiHoooong/AirliftSilence)（MIT）—— 静音资源与替换协议。
- [AirCard](https://github.com/mak5er/AirCard-iOS) —— Rust Airlift 核心。
- [placard](https://github.com/frs0n/placard)（frs0n）—— iOS 容器访问研究。
- [LocalDevVPN](https://github.com/jkcoxson/LocalDevVPN) / [StosVPN](https://github.com/SideStore/StosVPN)（SideStore Team / Stossy11、jkcoxson 及贡献者）—— 内置隧道使用了经过改写的数据包处理代码。见[来源与许可证](Vendor/LocalTunnel/README.md)，App 内也保留了原始许可证。

## 许可证

AirBeepSwap 以 [GNU 通用公共许可证 v3.0](LICENSE) 发布（沿用所基于的 AirBeep 代码的许可证）。
