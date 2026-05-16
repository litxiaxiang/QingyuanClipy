import SwiftUI
import SwiftData
import AppKit

class PopupManager {
    static let shared = PopupManager()
    
    private var window: ClipboardPopupWindow?
    
    func togglePopup(with container: ModelContainer) {
        if let win = window, win.isVisible {
            hidePopup()
            return
        }

        if window == nil {
            var rootView = ClipboardPopupView()
            
            // 将原先写死在 Menu 里的“选中->粘贴”逻辑转移到控制层
            rootView.onSelect = { [weak self] item in
                self?.handleSelection(for: item)
            }
            
            let wrappedView = rootView
                .frame(width: 300, height: 260) // 只需要展示 5 行和底部操作栏，降低默认高度
                .modelContainer(container)
            
            window = ClipboardPopupWindow(rootView: wrappedView)
            window?.onHide = { 
                // 可以在这里处理清理状态
                // 比如 window = nil (如需每次重新创建)
            }
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
        window?.closePanel()
    }
    
    // MARK: - 粘贴操作控制
    
    private func handleSelection(for item: ClipItem) {
        // 1. 将选中的内容放回剪贴板首位
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let ignoreType = NSPasteboard.PasteboardType("com.qingyuanclipy.ignore")
        pasteboard.setData(Data(), forType: ignoreType)
        
        if item.itemType == "text", let text = item.textContent {
            pasteboard.setString(text, forType: .string)
        } else if item.itemType == "image", let imgData = item.imageData {
            pasteboard.setData(imgData, forType: .tiff)
        }
        
        // 2. 隐藏弹窗，归还系统焦点
        hidePopup()
        NSApp.hide(nil)
        
        // 3. 延时发送 Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.triggerCmdV()
        }
    }
    
    private func triggerCmdV() {
        let vKeyCode: CGKeyCode = 0x09
        
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true) else { return }
        keyDownEvent.flags = .maskCommand
        keyDownEvent.post(tap: .cghidEventTap)
        
        guard let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false) else { return }
        keyUpEvent.flags = .maskCommand
        keyUpEvent.post(tap: .cghidEventTap)
    }
}