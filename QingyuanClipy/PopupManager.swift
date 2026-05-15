import SwiftUI
import SwiftData
import AppKit

class PopupManager {
    static let shared = PopupManager()
    
    private var window: NSPanel?
    
    func showPopup(with container: ModelContainer) {
        if window == nil {
            // 我们复用之前写的菜单视图，并注入数据库环境
            let rootView = ClipboardMenuView()
                .padding()
                .frame(width: 300) // 设定弹出面板宽度
                .modelContainer(container)
            
            let host = NSHostingController(rootView: rootView)
            
            // 创建一个无边框的浮动面板
            window = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
                styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
                backing: .buffered,
                defer: false
            )
            
            window?.isFloatingPanel = true
            window?.level = .popUpMenu // 显示在所有应用最顶层
            window?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95)
            window?.isOpaque = false
            window?.hasShadow = true
            window?.contentViewController = host
            
            // 当点击面板外部或者失去焦点时，自动关闭该窗口
            window?.hidesOnDeactivate = true
        }
        
        // 获取当前鼠标指针的位置
        let mouseLocation = NSEvent.mouseLocation
        
        if let win = window {
            // 将窗口弹出的位置设置在鼠标当前位置的右下方一点点
            let targetPoint = NSPoint(x: mouseLocation.x, y: mouseLocation.y)
            win.setFrameTopLeftPoint(targetPoint)
            
            // 使得本应用成为活动状态（获得键盘焦点），并前置窗口
            NSApp.activate(ignoringOtherApps: true)
            win.makeKeyAndOrderFront(nil)
        }
    }
    
    func hidePopup() {
        window?.orderOut(nil)
    }
}