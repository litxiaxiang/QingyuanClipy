import Cocoa
import Carbon

class GlobalHotKey {
    static let shared = GlobalHotKey()
    var action: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?

    func registerCmdShiftV() {
        // 注册键盘事件拦截回调
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            // 当按下触发时，回到主线程执行动作
            DispatchQueue.main.async {
                GlobalHotKey.shared.action?()
            }
            return noErr
        }, 1, &eventType, nil, nil)
        
        // 0x09 对应的 keyCode 是按键 'V'
        let keyCode = UInt32(0x09)
        // Command 键 + Shift 键的 Carbon 修饰符组合
        let modifiers = UInt32(cmdKey | shiftKey)
        
        let signature = UTGetOSTypeFromString("CLPY" as CFString)
        var hotKeyID = EventHotKeyID(signature: signature, id: 1)
        
        // 注册热键
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}