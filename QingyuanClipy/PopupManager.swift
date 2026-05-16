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
                
                // 明确指定窗口尺寸，避免 SwiftUI 尚未渲染布局导致 frame 尺寸获取不准
                let expectedWidth: CGFloat = 320
                let expectedHeight: CGFloat = 280
                
                // 强制更新成目标尺寸
                win.setContentSize(NSSize(width: expectedWidth, height: expectedHeight))
                
                // 计算窗口左下角坐标 (macOS 坐标原点在左下角)
                // 默认将窗口弹出的位置设置在鼠标右下方
                var originX = mouseLocation.x + 5
                var originY = mouseLocation.y - expectedHeight - 5
                
                // 边界碰撞检测与修正
                // 1. 如果右侧超出屏幕边缘，将窗口左移
                if originX + expectedWidth > screenVisibleFrame.maxX {
                    originX = mouseLocation.x - expectedWidth - 5
                }
                
                // 2. 如果底部超出屏幕边缘，将窗口上移
                if originY < screenVisibleFrame.minY {
                    originY = screenVisibleFrame.minY + 5
                }
                
                // 3. 如果顶部超出屏幕边缘（由于我们是默认在鼠标下方弹出，此情况较罕见，但兜底保护）
                if originY + expectedHeight > screenVisibleFrame.maxY {
                    originY = screenVisibleFrame.maxY - expectedHeight - 5
                }
                
                // 4. 左侧兜底保护
                if originX < screenVisibleFrame.minX {
                    originX = screenVisibleFrame.minX + 5
                }
                
                win.setFrameOrigin(NSPoint(x: originX, y: originY))
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