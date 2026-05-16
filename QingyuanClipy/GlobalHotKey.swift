import Cocoa
import Carbon

class GlobalHotKey {
    static let shared = GlobalHotKey()
    var action: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var isHandlerInstalled = false
    
    // 默认快捷键 Option + V
    // V 的 keyCode = 0x09 (9)
    let defaultKeyCode: UInt16 = 9
    let defaultModifiers: NSEvent.ModifierFlags = .option
    
    var currentKeyCode: UInt16 {
        get {
            if UserDefaults.standard.object(forKey: "hotKeyCode") != nil {
                return UInt16(UserDefaults.standard.integer(forKey: "hotKeyCode"))
            }
            return defaultKeyCode
        }
    }
    
    var currentModifiers: NSEvent.ModifierFlags {
        get {
            if UserDefaults.standard.object(forKey: "hotKeyModifiers") != nil {
                return NSEvent.ModifierFlags(rawValue: UInt(UserDefaults.standard.integer(forKey: "hotKeyModifiers")))
            }
            return defaultModifiers
        }
    }
    
    func saveHotKey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        UserDefaults.standard.set(Int(keyCode), forKey: "hotKeyCode")
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: "hotKeyModifiers")
        
        let isEnabled = UserDefaults.standard.object(forKey: "isHotKeyEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "isHotKeyEnabled")
        if isEnabled {
            register()
        }
    }

    func register() {
        unregister()
        
        if !isHandlerInstalled {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            
            InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
                DispatchQueue.main.async {
                    GlobalHotKey.shared.action?()
                }
                return noErr
            }, 1, &eventType, nil, nil)
            isHandlerInstalled = true
        }
        
        let keyCode = UInt32(currentKeyCode)
        let modifiers = carbonModifiers(from: currentModifiers)
        
        let signature = OSType(0x434C5059) // "CLPY"
        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
    
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
    
    private func carbonModifiers(from eventModifiers: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if eventModifiers.contains(.command) { modifiers |= UInt32(cmdKey) }
        if eventModifiers.contains(.option)  { modifiers |= UInt32(optionKey) }
        if eventModifiers.contains(.control) { modifiers |= UInt32(controlKey) }
        if eventModifiers.contains(.shift)   { modifiers |= UInt32(shiftKey) }
        return modifiers
    }
}
