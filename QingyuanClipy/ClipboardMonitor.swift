import Foundation
import AppKit

@Observable
class ClipboardMonitor {
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?
    
    // 增加数据类型区分：itemType（"text"或"image"）、文本内容、二进制图片数据
    var onNewCopy: ((_ itemType: String, _ text: String?, _ imgData: Data?) -> Void)?

    func start() {
        // 每 0.5 秒轮询一次剪贴板
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        // 剪贴板 changeCount 增加，说明发生了复制或剪切
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            // 如果遇到是应用程序自身写回的剪贴板内容（包含特定的忽略标记），则不需要保存到历史记录
            let ignoreType = NSPasteboard.PasteboardType("com.qingyuanclipy.ignore")
            if pasteboard.data(forType: ignoreType) != nil {
                return
            }
            
            // 优先检查是否有图片格式（如 TIFF 或 PNG）
            // 注意：某些应用复制图片时也会附带文件路径文本，所以优先拦截图片
            let imageTypes: [NSPasteboard.PasteboardType] = [.tiff, .png]
            if let type = pasteboard.availableType(from: imageTypes),
               let data = pasteboard.data(forType: type) {
                onNewCopy?("image", nil, data)
                return
            }
            
            // 如果不是图片，尝试获取纯文本
            if let newString = pasteboard.string(forType: .string) {
                // 如果不是空字符串，就抛出回调
                let trimmed = newString.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    onNewCopy?("text", newString, nil)
                }
            }
        }
    }
}