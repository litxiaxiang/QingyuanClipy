import SwiftUI
import AppKit

class PermissionGuideWindowController: NSWindowController, NSWindowDelegate {
    static let shared = PermissionGuideWindowController()
    
    private var isAskingForPermission = false
    
    init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "需要辅助功能权限"
        panel.isFloatingPanel = false
        panel.level = .normal
        panel.center()
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        
        super.init(window: panel)
        window?.delegate = self
        
        let contentView = PermissionGuideView(onClose: { [weak self] in
            self?.closeWindow()
        })
        
        panel.contentView = NSHostingView(rootView: contentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showWindow() {
        if !isAskingForPermission {
            isAskingForPermission = true
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            // 延时极小的一段时间（等我们自己的引导窗口弹出来后），再去强制戳一下系统
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                AccessibilityManager.shared.triggerSystemPromptForcefully()
            }
            
            // 开始轮询，一旦授权则自动关闭
            AccessibilityManager.shared.startPolling()
            
            // 监听权限变更
            NotificationCenter.default.addObserver(forName: NSNotification.Name("AccessibilityPermissionGranted"), object: nil, queue: .main) { [weak self] _ in
                self?.closeWindow()
            }
        }
    }
    
    func closeWindow() {
        window?.orderOut(nil)
        isAskingForPermission = false
        AccessibilityManager.shared.stopPolling()
    }
}
