import SwiftUI

struct PermissionGuideView: View {
    @ObservedObject var accessibilityManager = AccessibilityManager.shared
    var onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.orange)
            
            Text("需要辅助功能权限")
                .font(.headline)
            
            Text("为了使青元 Clipy 能够实现自动粘贴剪贴板内容到目标应用，我们需要辅助功能权限。")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("1. 请在弹出的系统提示中点击“打开系统设置”")
                Text("2. 在隐私与安全性 -> 辅助功能 中找到 青元 Clipy")
                Text("3. 将其右侧的开关打开")
            }
            .font(.callout)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            HStack(spacing: 16) {
                Button("稍后设置") {
                    onClose()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("打开系统设置") {
                    accessibilityManager.openSystemPreferences()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 10)
        }
        .padding(30)
        .frame(width: 400)
        // 确保轮询的时候UI也能体现，不过目前一旦授权窗口就关了。
    }
}

#Preview {
    PermissionGuideView(onClose: {})
}
