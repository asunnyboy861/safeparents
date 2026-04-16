import SwiftUI

extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}

extension View {
    func ipadAdaptivePadding() -> some View {
        self.padding(.horizontal, UIDevice.isIPad ? 60 : 24)
    }
    
    func ipadAdaptiveButtonWidth() -> some View {
        self.frame(maxWidth: UIDevice.isIPad ? 400 : .infinity)
    }
}
