import SwiftUI
import ApplicationServices
import Combine

class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published var isTrusted: Bool = false
    private var timer: Timer?
    
    init() {
        self.isTrusted = checkTrust(prompt: false)
    }
    
    @discardableResult
    func checkTrust(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        DispatchQueue.main.async {
            self.isTrusted = trusted
        }
        
        return trusted
    }
    
    func startPolling() {
        // 如果已经获得权限，直接返回
        if isTrusted { return }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let trusted = AXIsProcessTrusted()
            if trusted {
                DispatchQueue.main.async {
                    self.isTrusted = true
                    NotificationCenter.default.post(name: NSNotification.Name("AccessibilityPermissionGranted"), object: nil)
                }
                self.stopPolling()
            }
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    func openSystemPreferences() {
        // 打开系统设置 -> 隐私与安全性 -> 辅助功能
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    func triggerSystemPromptForcefully() {
        // 先再次调用标准 API
        self.checkTrust(prompt: true)
        
        // 构造一个虚拟按键事件（按键码 0x3F 是 fn/globe 键，副作用极小）去主动“撞击”系统的 TCC 防火墙
        // 这个动作没有权限会被系统拦截，但同时就会百分百触发系统原生弹窗并自动加进设置列表
        if let eventDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x3F, keyDown: true) {
            eventDown.post(tap: .cghidEventTap)
        }
        if let eventUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x3F, keyDown: false) {
            eventUp.post(tap: .cghidEventTap)
        }
    }
}
