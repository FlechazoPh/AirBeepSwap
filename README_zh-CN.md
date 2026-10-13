# ToneSwap

> 🌍 **Languages:** [English](./README.md) | 简体中文

ToneSwap 是一款 iOS 工具，用于自定义通话录音提示音 —— 即 iOS 在通话录音开始和结束时播放的提示音。一键静音，或为每段提示音替换成你自己的音频：选择文件、查看波形与时长、试听后应用。首次修改前自动备份原始提示音，一键即可恢复。

## 功能特性

- 一个开关静音两段提示音（等长静音，与 AirBeep 一致）。
- **自定义提示音**：开始/结束提示音各自独立，可选择任意本地音频文件（MP3、M4A、WAV、CAF、AIFF…）。
- 自动转码为系统要求的精确格式（开始提示音：AAC 44.1 kHz 单声道 `.m4a`；结束提示音：PCM s16le 48 kHz 单声道 `.caf`），iOS 可原生播放替换后的文件。
- 波形图显示、原音与替换音频的时长对比、应用前可在 App 内试听。
- 首次修改前自动备份原始提示音文件 —— 备份会被保留且绝不会被覆盖。
- 每次写入后都会进行文件回读校验。
- 一键恢复原始提示音。
- 支持英文与简体中文界面。

## 工作原理

ToneSwap 通过与 [AirBeep](https://github.com/LinkPass888/AirBeep) 相同的 AirTraffic 沙盒逃逸访问系统提示音文件：

- `/var/mobile/Library/CallServices/Greetings/default/StartDisclosureWithTone.m4a`
- `/var/mobile/Library/CallServices/Greetings/default/StopDisclosure.caf`

App 将自己伪装成一台 Mac 配对主机（Bonjour/RPPairing）与本机配对，通过隧道访问设备的 lockdown 服务，再经 Airlift 核心执行文件操作。备份保存在应用 Documents 目录下的 `ToneSwapBackups` 中。

## 系统要求

- 一台运行 **iOS/iPadOS 18.0 – 27.2 B2** 的实体 iPhone 或 iPad。
- iPhone 需先与 App 完成配对并连接 LocalDevVPN（App 内有设置向导）。
- 本地构建需 Xcode 27 或更高版本。
- 仓库提供的 GitHub Actions 工作流可在云端构建 unsigned IPA。

> ToneSwap 依赖非公开的系统行为，不同 iOS 版本之间兼容性可能发生变化。

## 使用

1. 安装并打开 App。
2. 完成 **Airlift 设置**：开始配对，在"设置 › 隐私与安全性 › 开发者模式"中确认 PIN，再连接 LocalDevVPN。
3. 使用静音开关，或为每段提示音选择自定义音频并点击**替换为此音频**。

## 构建

打开 `toneswap.xcodeproj`，选择 `toneswap` target，设置你的签名团队，然后构建到实体设备。

如需构建 unsigned IPA，请在 GitHub Actions 中运行 `Release unsigned IPA` 工作流。成品文件名为 `toneswap-v<version>-unsigned.ipa`。

## 法律声明

移除或替换提示音后，对方将不再收到"通话正在被录音"的告知。许多国家和地区法律要求录音前告知所有参与方。请仅在你自己的设备上、且在法律允许的情况下使用本应用，遵守适用法律是你的责任。

## 致谢

- [AirBeep](https://github.com/LinkPass888/AirBeep)（LinkPass888，GPLv3）—— 本项目基于该 iOS App 修改。
- [airlift](https://github.com/0xjohnnydev/airlift)（0xjohnnydev，MIT）—— AirTraffic 沙盒逃逸研究。
- [AirliftSilence](https://github.com/YiHoooong/AirliftSilence)（MIT）—— 静音资源与替换协议。
- [AirCard](https://github.com/mak5er/AirCard-iOS) —— Rust Airlift 核心。
- [placard](https://github.com/frs0n/placard)（frs0n）—— iOS 容器访问研究。

## 许可证

ToneSwap 以 [GNU 通用公共许可证 v3.0](LICENSE) 发布（沿用所基于的 AirBeep 代码的许可证）。
