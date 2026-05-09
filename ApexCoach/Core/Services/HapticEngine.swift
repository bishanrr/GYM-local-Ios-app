#if canImport(UIKit)
import UIKit
#endif

enum HapticImpactStyle {
    case light
    case medium
    case heavy

    #if canImport(UIKit)
    var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light:
            return .light
        case .medium:
            return .medium
        case .heavy:
            return .heavy
        }
    }
    #endif
}

enum HapticNotificationType {
    case success
    case warning
    case error

    #if canImport(UIKit)
    var uiType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success:
            return .success
        case .warning:
            return .warning
        case .error:
            return .error
        }
    }
    #endif
}

enum HapticEngine {
    static func impact(_ style: HapticImpactStyle = .medium) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: style.uiStyle).impactOccurred()
        #endif
    }

    static func notify(_ type: HapticNotificationType) {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(type.uiType)
        #endif
    }
}
