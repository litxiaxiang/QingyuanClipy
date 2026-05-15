import Foundation
import AppKit

@Observable
class ClipboardMonitor {
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?
    
    // 当检测到新的纯文本复制时，触发该回调
    var onNewCopy: ((String) -> Void)?

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
            
            // 尝试获取纯文本
            if let newString = pasteboard.string(forType: .string) {
                // 如果不是空字符串，就抛出回调
                let trimmed = newString.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    onNewCopy?(newString)
                }
            }
        }
    }
}