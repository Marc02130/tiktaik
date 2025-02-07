//
// NetworkMonitor.swift
// TIKtAIk
//

import Network
import SwiftUI

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected = true
    @Published private(set) var isOnCellular = false
    private let monitor = NWPathMonitor()
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.isOnCellular = path.usesInterfaceType(.cellular)
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
    
    deinit {
        monitor.cancel()
    }
}