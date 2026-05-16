import AppKit
import SwiftUI

class ClipboardPopupWindow: NSPanel {
    
    // 隐藏回调闭包
    var onHide: (() -> Void)?
    
    init(rootView: some View) {
        let contentRect = NSRect(x: 0, y: 0, width: 300, height: 260)
        
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .popUpMenu
        self.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95)
        self.isOpaque = false
        self.hasShadow = true
        self.hidesOnDeactivate = false // 禁用系统的该行为，我们通过自管事件做彻底关闭
        
        self.contentViewController = NSHostingController(rootView: rootView)
        
        // 监听焦点失去事件
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.closePanel()
        }
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    func closePanel() {
        self.orderOut(nil)
        onHide?()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
