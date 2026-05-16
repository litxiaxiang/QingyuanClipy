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
                .frame(width: 320, height: 280) // 适应最近 5 条的合适高度
                .modelContainer(container)
            
            window = ClipboardPopupWindow(rootView: wrappedView)
            window?.onHide = { [weak self] in
                // 窗口隐藏后将其销毁，下次打开重新创建，确保 SwiftUI 的 @State（如展开状态）自然重置
                self?.window = nil
            }
        }
        
        if let win = window {
            // 获取当前鼠标指针的位置
            let mouseLocation = NSEvent.mouseLocation
            
            // 获取鼠标所在的屏幕
            let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
            
            if let screen = screen {
                let screenVisibleFrame = screen.visibleFrame
                let windowWidth = win.frame.width
                let windowHeight = win.frame.height
                
                // 默认将窗口弹出的位置设置在鼠标右下方
                var topLeftX = mouseLocation.x + 2
                var topLeftY = mouseLocation.y - 2
                
                // 边界碰撞检测与修正 (macOS 坐标系原点在左下角)
                // 1. 如果右侧超出屏幕可视边缘
                if topLeftX + windowWidth > screenVisibleFrame.maxX {
                    topLeftX = screenVisibleFrame.maxX - windowWidth - 5
                }
                
                // 2. 如果底部超出屏幕可视边缘 (注意 topLeftY - windowHeight 就是底部的高度)
                if topLeftY - windowHeight < screenVisibleFrame.minY {
                    topLeftY = screenVisibleFrame.minY + windowHeight + 5
                }
                
                // 3. 兜底保护，确保不超过左边和上边
                topLeftX = max(topLeftX, screenVisibleFrame.minX + 5)
                topLeftY = min(topLeftY, screenVisibleFrame.maxY - 5)
                
                win.setFrameTopLeftPoint(NSPoint(x: topLeftX, y: topLeftY))
            } else {
                // 如果找不到屏幕，作为兜底居中
                win.center()
            }
            
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