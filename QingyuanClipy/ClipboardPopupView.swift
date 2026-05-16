import SwiftUI
import SwiftData

/// 专为独立浮窗设计的剪贴板历史视图
struct ClipboardPopupView: View {
    @Query(sort: \ClipItem.timestamp, order: .reverse) private var items: [ClipItem]
    @Environment(\.modelContext) private var modelContext
    
    // 把“选中某个 item”的回调暴露给外部，解耦粘贴逻辑
    var onSelect: ((ClipItem) -> Void)?
    
    @State private var hoveredItemID: PersistentIdentifier?
    @State private var showAllItems: Bool = false
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部搜索/标题栏区域 (Raycast 风格，紧凑版)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("搜索剪贴板历史...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)
                    .focused($isSearchFocused)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        isSearchFocused = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 1)
            
            if items.isEmpty {
                Spacer()
                Text("剪贴板为空")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        let filteredItems = searchText.isEmpty ? items : items.filter { item in
                            if item.itemType == "text", let text = item.textContent {
                                return text.localizedCaseInsensitiveContains(searchText)
                            }
                            return false
                        }
                        
                        // 搜索时自动展示所有过滤结果
                        let displayItems = (showAllItems || !searchText.isEmpty) ? Array(filteredItems) : Array(filteredItems.prefix(5))
                        
                        if displayItems.isEmpty {
                            Text("无匹配结果")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                                .padding(.vertical, 20)
                        } else {
                            ForEach(displayItems) { item in
                                popupItemCard(for: item)
                                    .onHover { isHovered in
                                        if isHovered {
                                            hoveredItemID = item.id
                                        } else if hoveredItemID == item.id {
                                            hoveredItemID = nil
                                        }
                                    }
                                    .onTapGesture {
                                        onSelect?(item)
                                    }
                            }
                        }
                        
                        if !showAllItems && searchText.isEmpty && items.count > 5 {
                            HStack {
                                Spacer()
                                Text("更多...")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onHover { isHovered in
                                if isHovered {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showAllItems = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                }
            }
            
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 1)
            
            // 底部操作区
            HStack {
                Text("共 \(items.count) 条记录")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    clearAll()
                }) {
                    Text("清空列表")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.03))
        }
        .background(
            ZStack {
                VisualEffectView().ignoresSafeArea()
                // 在磨砂玻璃之上叠加一层半透明的系统窗口背景色，
                // 大幅提亮弹窗本体，防止被背后深色的窗口带暗
                Color(nsColor: .windowBackgroundColor).opacity(0.75)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .onAppear {
            showAllItems = false
            searchText = ""
            isSearchFocused = true
        }
    }
    
    // 列表项卡片
    @ViewBuilder
    private func popupItemCard(for item: ClipItem) -> some View {
        let isHovered = (hoveredItemID == item.id)
        
        HStack(spacing: 8) {
            // Icon 区域 (紧凑型)
            if item.itemType == "text" {
                Image(systemName: "text.rectangle.fill")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(isHovered ? .primary : .secondary)
                    .frame(width: 16)
            } else if item.itemType == "image" {
                Image(systemName: "photo.fill")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(isHovered ? .primary : .secondary)
                    .frame(width: 16)
            } else {
                Image(systemName: "doc.fill")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(isHovered ? .primary : .secondary)
                    .frame(width: 16)
            }
            
            // 文本信息区域 - 移除时间，单行显示
            if item.itemType == "text", let text = item.textContent {
                Text(getSingleLinePreview(for: text))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            } else if item.itemType == "image", let imgData = item.imageData {
                Text("图片 [\(imgData.count / 1024) KB]")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
            } else {
                Text("未知内容")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
            }
            
            Spacer(minLength: 0)
            
            // 图像预览缩略图 (缩小)
            if item.itemType == "image", let imgData = item.imageData, let nsImage = NSImage(data: imgData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            
            // 悬停提示 (极简回车符)
            if isHovered {
                Image(systemName: "return")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5) // 高度显著收紧
        .background(isHovered ? Color.primary.opacity(0.1) : Color.clear) // 悬停整行底色，类似原生菜单
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
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

// macOS 原生磨砂玻璃材质
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow // 允许透视背景窗口
        view.state = .active
        view.material = .menu // 改为 menu 材质，比 popover 更加明亮通透
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
