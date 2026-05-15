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
        
        // 注册全局热键 Cmd + Shift + V
        setupGlobalHotKey()
    }
    
    private func setupGlobalHotKey() {
        GlobalHotKey.shared.action = { [self] in
            // 按下热键时，在当前鼠标位置弹出剪贴板浮窗
            PopupManager.shared.showPopup(with: sharedModelContainer)
        }
        GlobalHotKey.shared.registerCmdShiftV()
    }

    private func setupClipboardMonitor() {
        monitor.onNewCopy = { newText in
            // 当发生复制时，开启一个 Task 保存到数据库
            Task { @MainActor in
                let newItem = ClipItem(content: newText)
                sharedModelContainer.mainContext.insert(newItem)
                try? sharedModelContainer.mainContext.save()
            }
        }
        monitor.start()
    }

    var body: some Scene {
        // 配置菜单栏 (Status Bar) 项目
        MenuBarExtra("QingyuanClipy", systemImage: "paperclip") {
            // 提取单独的视图用于在菜单上展示最近的剪贴板记录
            ClipboardMenuView()
                .modelContainer(sharedModelContainer) // 需要给视图内部提供 Context
            
            Divider()
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }

        // 偏好设置窗口 (可以在按需时弹出)
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
