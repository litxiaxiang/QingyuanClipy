<p align="center">
  <img src="Icon/LOGO-iOS-Default-1024x1024@1x.png" width="200" alt="QingyuanClipy Logo">
</p>

# 青元 Clipy

**青元 Clipy** 是一款为 macOS 设计的轻量级剪贴板管理工具。它能够隐式地记录你的剪贴板历史，并通过快捷键快速唤出弹窗进行查看和极速粘贴。

## ✨ 特性 (Features)

- **剪贴板监听**: 后台自动监听并保存剪贴板历史记录。
- **全局快捷键**: 支持通过自定义全局快捷键快速呼出剪贴板历史菜单。
- **弹窗交互**: 原生且快速的 macOS 浮窗交互体验 (基于 SwiftUI)。
- **快捷粘贴**: 选择历史记录后可快速在当前焦点应用中执行粘贴操作。
- **配置与设置**: 提供简单易用的设置界面。

## 🚀 安装 (Installation)

### 从源码编译

1. 确保你的 Mac 上已经安装了最新版本的 [Xcode](https://developer.apple.com/xcode/)。
2. 克隆本仓库到本地：
   ```bash
   git clone https://github.com/YourUsername/QingyuanClipy.git
   ```
3. 在 Xcode 中打开 `QingyuanClipy.xcodeproj`。
4. 选择你的 Mac 作为编译目标，点击 **Run (Cmd + R)** 即可编译并运行。

## ⚙️ 权限设置

为了使 QingyuanClipy 能够正常监听并在其他应用中自动执行粘贴操作，请确保赋予其**辅助功能 (Accessibility)** 权限：
1. 打开 macOS 的 **系统设置 > 隐私与安全性 > 辅助功能**。
2. 找到 QingyuanClipy 并将其开关打开（如未找到可点击 "+" 手动添加应用）。

## 🤝 贡献 (Contributing)

欢迎提交 Issue 和 Pull Request！
1. Fork 本仓库
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 📄 许可证 (License)

本项目基于 [MIT License](LICENSE) 开源。
