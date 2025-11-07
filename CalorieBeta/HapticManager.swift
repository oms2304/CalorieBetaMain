import SwiftUI
import UIKit

class HapticManager {
    static let instance = HapticManager()
    private init() {}
    
    func feedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle){
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType){
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
<<<<<<< HEAD
        
    }
    
    

}



=======
    }
}
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
