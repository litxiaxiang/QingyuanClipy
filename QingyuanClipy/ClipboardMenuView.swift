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
    
    // 写入剪贴板（模拟粘贴操作）
    private func paste(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        // 实际如果要触发系统粘贴，需要结合 Accessibility API (CGEvent)，目前先简单将其置回首位
    }
    
    // 清空 SwiftData 数据
    @Environment(\.modelContext) private var modelContext
    private func clearAll() {
        for item in items {
            modelContext.delete(item)
        }
    }
}