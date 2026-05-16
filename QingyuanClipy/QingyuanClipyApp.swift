//
//  QingyuanClipyApp.swift
//  QingyuanClipy
//
//  Created by 黄登亮 on 2026/5/15.
//

import SwiftUI
import SwiftData

@main
struct QingyuanClipyApp: App {
    // 监听器实例
    let monitor = ClipboardMonitor()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ClipItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // 在应用启动时设置剪贴板监听逻辑
        setupClipboardMonitor()
        
        // 注册全局热键 Option + V
        setupGlobalHotKey()
    }
    
    private func setupGlobalHotKey() {
        GlobalHotKey.shared.action = { [self] in
            // 按下热键时，在当前鼠标位置弹出剪贴板浮窗
            PopupManager.shared.showPopup(with: sharedModelContainer)
        }
        
        // 读取快捷键开关设置，默认开启
        let isEnabled = UserDefaults.standard.object(forKey: "isHotKeyEnabled") as? Bool ?? true
        if isEnabled {
            GlobalHotKey.shared.registerOptionV()
        }
    }

    private func setupClipboardMonitor() {
        monitor.onNewCopy = { itemType, text, imgData in
            // 当发生复制时，开启一个 Task 保存到数据库
            Task { @MainActor in
                let newItem = ClipItem(itemType: itemType, textContent: text, imageData: imgData)
                let context = sharedModelContainer.mainContext
                context.insert(newItem)
                try? context.save()
                
                // 限制最大历史记录数量
                let maxCount = UserDefaults.standard.integer(forKey: "maxHistoryCount")
                let limit = maxCount > 0 ? maxCount : 50
                
                let fetchDescriptor = FetchDescriptor<ClipItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
                if let items = try? context.fetch(fetchDescriptor), items.count > limit {
                    for itemToDelete in items.dropFirst(limit) {
                        context.delete(itemToDelete)
                    }
                    try? context.save()
                }
            }
        }
        monitor.start()
    }

    @AppStorage("statusBarIcon") private var statusBarIcon: String = "paperclip"

    var body: some Scene {
        // 配置菜单栏 (Status Bar) 项目
        MenuBarExtra("QingyuanClipy", systemImage: statusBarIcon) {
            // 提取单独的视图用于在菜单上展示最近的剪贴板记录
            ClipboardMenuView()
                .modelContainer(sharedModelContainer) // 需要给视图内部提供 Context
            
            Divider()
            
            if #available(macOS 14.0, *) {
                SettingsLink {
                    Text("偏好设置...")
                }
                .keyboardShortcut(",", modifiers: .command)
            } else {
                Button("偏好设置...") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            
            Button("退出 青元 Clipy") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }

        // 偏好设置窗口
        Settings {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }
    }
}
