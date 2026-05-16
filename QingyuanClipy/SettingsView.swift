import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("maxHistoryCount") private var maxHistoryCount: Int = 50
    @AppStorage("isHotKeyEnabled") private var isHotKeyEnabled: Bool = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        TabView {
            GeneralSettingsView(
                launchAtLogin: $launchAtLogin,
                maxHistoryCount: $maxHistoryCount
            )
            .tabItem {
                Label("通用", systemImage: "gearshape")
            }
            
            ShortcutSettingsView(
                isHotKeyEnabled: $isHotKeyEnabled
            )
            .tabItem {
                Label("快捷键", systemImage: "keyboard")
            }
            
            AboutSettingsView()
            .tabItem {
                Label("关于", systemImage: "info.circle")
            }
        }
        .frame(width: 480, height: 320)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .onAppear {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}

struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var maxHistoryCount: Int
    @AppStorage("statusBarIcon") private var statusBarIcon: String = "paperclip"
    
    // 预设的状态栏图标选项
    private let availableIcons = [
        ("回形针", "paperclip"),
        ("剪切板", "doc.on.clipboard"),
        ("剪刀", "scissors"),
        ("列表", "list.clipboard"),
        ("普通", "clipboard"),
        ("托盘", "tray"),
        ("心形", "heart")
    ]
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 24) {
                // 状态栏图标设置
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text("状态栏图标：")
                        .frame(width: 120, alignment: .trailing)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("", selection: $statusBarIcon) {
                            ForEach(availableIcons, id: \.1) { item in
                                HStack {
                                    Image(systemName: item.1)
                                    Text(item.0)
                                }
                                .tag(item.1)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    }
                }
                
                Divider()
                
                // 开机自启
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text("开机自启动：")
                        .frame(width: 120, alignment: .trailing)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("登录时自动启动青元 Clipy", isOn: $launchAtLogin)
                            .toggleStyle(.checkbox)
                            .onChange(of: launchAtLogin) { _, newValue in
                                handleLaunchAtLoginChange(newValue: newValue)
                            }
                    }
                }
                
                Divider()
                
                // 历史记录容量
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text("最大历史保存数量：")
                        .frame(width: 120, alignment: .trailing)
                        .foregroundColor(.secondary)
                        
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Picker("", selection: $maxHistoryCount) {
                                Text("10 条").tag(10)
                                Text("30 条").tag(30)
                                Text("50 条").tag(50)
                                Text("100 条").tag(100)
                                Text("200 条").tag(200)
                                Text("500 条").tag(500)
                            }
                            .labelsHidden()
                            .frame(width: 120)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 10)
        }
    }
    
    private func handleLaunchAtLoginChange(newValue: Bool) {
        do {
            if newValue {
                if SMAppService.mainApp.status == .enabled { return }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status != .enabled { return }
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("修改开机自启状态失败: \(error)")
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

struct ShortcutSettingsView: View {
    @Binding var isHotKeyEnabled: Bool
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text("唤出：")
                        .frame(width: 120, alignment: .trailing)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("启用全局快捷键", isOn: $isHotKeyEnabled)
                            .toggleStyle(.checkbox)
                            .onChange(of: isHotKeyEnabled) { _, newValue in
                                if newValue {
                                    GlobalHotKey.shared.registerOptionV()
                                } else {
                                    GlobalHotKey.shared.unregister()
                                }
                            }
                        
                        if isHotKeyEnabled {
                            HStack(spacing: 6) {
                                HStack(spacing: 4) {
                                    shortcutKeyView("⌥")
                                    Text("+").foregroundColor(.secondary)
                                    shortcutKeyView("V")
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 10)
        }
    }
    
    @ViewBuilder
    private func shortcutKeyView(_ text: String) -> some View {
        Text(text)
            .font(.system(.body, design: .rounded).bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
    }
}

struct AboutSettingsView: View {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 4) {
                Text("青元 Clipy")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("版本 \(appVersion)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("轻量、现代、极致流畅的剪贴板管理工具。\n让复制粘贴更加得心应手。")
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text("本项目的界面和灵感参考了优秀的开源项目：")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Link("Clipy (https://github.com/Clipy/Clipy)", destination: URL(string: "https://github.com/Clipy/Clipy")!)
                    .font(.caption)
            }
            .padding(.top, 8)
            
            Spacer()
            
            Text("Copyright © 2026 Qingyuan. All rights reserved.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
