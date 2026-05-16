import SwiftUI
import SwiftData

/// 专为独立浮窗设计的剪贴板历史视图
struct ClipboardPopupView: View {
    @Query(sort: \ClipItem.timestamp, order: .reverse) private var items: [ClipItem]
    @Environment(\.modelContext) private var modelContext
    
    // 把“选中某个 item”的回调暴露给外部，解耦粘贴逻辑
    var onSelect: ((ClipItem) -> Void)?
    
    @State private var showAllItems: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            if items.isEmpty {
                Text("剪贴板为空")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        let displayItems = showAllItems ? Array(items) : Array(items.prefix(5))
                        
                        ForEach(displayItems) { item in
                            popupItemCard(for: item)
                                .onTapGesture {
                                    onSelect?(item)
                                }
                        }
                        
                        if !showAllItems && items.count > 5 {
                            HStack {
                                Spacer()
                                Text("更多...")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // 点击“更多”时，通过动画展开余下的所有项目
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showAllItems = true
                                }
                            }
                        }
                    }
                    .padding(8)
                }
            }
            
            Divider()
            
            // 底部操作区
            HStack {
                Text("共 \(items.count) 条记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("清空") {
                    clearAll()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(10)
        }
        .onAppear {
            // 每次弹窗重新出现时，重置折叠状态
            showAllItems = false
        }
    }
    
    // 列表项卡片
    @ViewBuilder
    private func popupItemCard(for item: ClipItem) -> some View {
        HStack {
            if item.itemType == "text", let text = item.textContent {
                Image(systemName: "text.rectangle.fill")
                    .foregroundColor(.blue)
                Text(getSingleLinePreview(for: text))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                Spacer()
            } else if item.itemType == "image", let imgData = item.imageData {
                Image(systemName: "photo")
                    .foregroundColor(.purple)
                Text("图片 [\(imgData.count / 1024) KB]")
                    .foregroundColor(.primary)
                Spacer()
                if let nsImage = NSImage(data: imgData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .cornerRadius(4)
                }
            } else {
                Text("未知内容")
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1)) // 悬浮效果可用 hover 等扩展实现
        .cornerRadius(6)
        // 增加 contentShape 提供整行点击响应范围
        .contentShape(Rectangle()) 
    }
    
    private func getSingleLinePreview(for text: String) -> String {
        let lines = text.split(whereSeparator: \.isNewline)
        guard let firstLine = lines.first else { return "..." }
        let limit = 40
        return firstLine.count > limit ? firstLine.prefix(limit) + "..." : String(firstLine)
    }
    
    private func clearAll() {
        for item in items {
            modelContext.delete(item)
        }
    }
}
