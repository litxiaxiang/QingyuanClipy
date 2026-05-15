import SwiftUI
import SwiftData

struct ClipboardMenuView: View {
    // 获取最近复制的 10 条剪贴板内容，按时间倒序排列
    @Query(sort: \ClipItem.timestamp, order: .reverse) private var items: [ClipItem]
    
    var body: some View {
        if items.isEmpty {
            Text("剪贴板为空")
        } else {
            // 限制最多显示 10 条，避免菜单过长
            ForEach(items.prefix(10)) { item in
                Button(action: {
                    paste(text: item.content)
                }) {
                    Text(getSingleLinePreview(for: item.content))
                }
            }
            
            if !items.isEmpty {
                Divider()
                Button("清空历史记录") {
                    clearAll()
                }
            }
        }
    }
    
    // 提取文本预览，避免换行撑坏菜单
    private func getSingleLinePreview(for text: String) -> String {
        let lines = text.split(whereSeparator: \.isNewline)
        guard let firstLine = lines.first else { return "..." }
        let limit = 40
        return firstLine.count > limit ? firstLine.prefix(limit) + "..." : String(firstLine)
    }
    
    // 写入剪贴板并且自动粘贴
    private func paste(text: String) {
        // 1. 将选中的文本放回剪贴板首位
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // 2. 隐藏当前的剪贴板弹窗，让系统焦点回到之前的目标应用程序
        PopupManager.shared.hidePopup()
        
        // 3. 将应用置于后台，确保目标应用取得真正的输入焦点
        NSApp.hide(nil)
        
        // 4. 等待极小的时间让焦点稳固后，发送 Cmd+V 的击键事件
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            triggerCmdV()
        }
    }
    
    // 使用 CGEvent 模拟 Cmd+V 按键
    private func triggerCmdV() {
        let vKeyCode: CGKeyCode = 0x09 // 'V' 键
        
        // 按下 Command + V
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true) else { return }
        keyDownEvent.flags = .maskCommand
        keyDownEvent.post(tap: .cghidEventTap) // 发布到底层 HID 事件流
        
        // 松开 Command + V
        guard let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false) else { return }
        keyUpEvent.flags = .maskCommand
        keyUpEvent.post(tap: .cghidEventTap)
    }
    
    // 清空 SwiftData 数据
    @Environment(\.modelContext) private var modelContext
    private func clearAll() {
        for item in items {
            modelContext.delete(item)
        }
    }
}