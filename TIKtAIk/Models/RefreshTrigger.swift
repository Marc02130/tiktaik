import Foundation
import Observation

@Observable final class RefreshTrigger {
    var shouldRefresh = false
    
    func triggerRefresh() {
        shouldRefresh = true
    }
    
    func refreshCompleted() {
        shouldRefresh = false
    }
} 