import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ClipItem]

    var body: some View {
        VStack {
            Text("可以把这里做成偏好设置页面或剪贴板历史全屏页面")
                .padding()
        }
    }
}
