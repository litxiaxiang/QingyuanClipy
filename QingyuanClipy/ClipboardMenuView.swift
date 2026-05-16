import SwiftUI
import SwiftData

struct ClipboardMenuView: View {
    // 获取最近复制的 10 条剪贴板内容，按时间倒序排列
    @Query(sort: \ClipItem.timestamp, order: .reverse) private var items: [ClipItem]
    @AppStorage("maxHistoryCount") private var maxHistoryCount: Int = 50
    
    var body: some View {
        if items.isEmpty {
            Text("剪贴板为空")
        } else {
            // 前 10 条显示在一级菜单
            ForEach(items.prefix(10)) { item in
                menuItem(for: item)
            }
            
            // 第 11 条开始放在二级菜单里
            if items.count > 10 {
                Menu {
                    // 二级菜单再展示剩余的记录
                    let remainingCount = max(0, maxHistoryCount - 10)
                    ForEach(items.dropFirst(10).prefix(remainingCount)) { item in
                        menuItem(for: item)
                    }
                } label: {
                    Label("更多历史记录...", systemImage: "clock.fill")
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
    
    // 提取出来的复用视图，避免重复
    @ViewBuilder
    private func menuItem(for item: ClipItem) -> some View {
        Button(action: {
            paste(item: item)
        }) {
            if item.itemType == "text", let text = item.textContent {
                HStack {
                    Image(systemName: "text.rectangle.fill")
                    Text(getSingleLinePreview(for: text))
                        .lineLimit(1)
                }
            } else if item.itemType == "image", let imgData = item.imageData, NSImage(data: imgData) != nil {
                HStack {
                    Image(systemName: "photo")
                    Text("图片 [\(imgData.count / 1024) KB]")
                    // Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fit).frame(width: 40, height: 30) // 如果需要缩略图可恢复
                }
            } else {
                Text("未知类型内容")
            }
        }
        .help(item.itemType == "text" ? (item.textContent ?? "") : "图片组件")
    }
    
    // 提取文本预览，避免换行撑坏菜单
    private func getSingleLinePreview(for text: String) -> String {
        let lines = text.split(whereSeparator: \.isNewline)
        guard let firstLine = lines.first else { return "..." }
        let limit = 40
        return firstLine.count > limit ? firstLine.prefix(limit) + "..." : String(firstLine)
    }
    
    // 写入剪贴板并且自动粘贴
    private func paste(item: ClipItem) {
        // 1. 将选中的内容放回剪贴板首位
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // 添加一个自定义标记，让 ClipboardMonitor 识别并忽略自己写回的剪贴板内容
        let ignoreType = NSPasteboard.PasteboardType("com.qingyuanclipy.ignore")
        pasteboard.setData(Data(), forType: ignoreType)
        
        if item.itemType == "text", let text = item.textContent {
            pasteboard.setString(text, forType: .string)
        } else if item.itemType == "image", let imgData = item.imageData {
            // macOS 常用剪贴板图片格式为 TIFF 或 PNG
            pasteboard.setData(imgData, forType: .tiff)
        }
        
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