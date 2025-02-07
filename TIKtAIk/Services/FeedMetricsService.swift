//
// FeedMetricsService.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@Observable final class FeedMetricsService {
    private let db = Firestore.firestore()
    private var timings: [String: Date] = [:]
    
    /// Records feed load time
    func recordLoadTime(_ duration: TimeInterval, feedType: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FeedError.notAuthenticated
        }
        
        let metrics = [
            "userId": userId,
            "feedType": feedType,
            "loadTime": duration,
            "timestamp": Timestamp(date: Date())
        ] as [String : Any]
        
        try await db.collection("feedMetrics").addDocument(data: metrics)
    }
    
    /// Records video view duration
    func recordViewDuration(_ duration: TimeInterval, videoId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FeedError.notAuthenticated
        }
        
        let metrics = [
            "userId": userId,
            "videoId": videoId,
            "viewDuration": duration,
            "timestamp": Timestamp(date: Date())
        ] as [String : Any]
        
        try await db.collection("viewMetrics").addDocument(data: metrics)
    }
    
    /// Starts timing an operation
    func startTiming(_ operation: String) {
        timings[operation] = Date()
    }
    
    /// Ends timing an operation and returns duration
    func endTiming(_ operation: String) -> TimeInterval? {
        guard let start = timings[operation] else { return nil }
        timings.removeValue(forKey: operation)
        return Date().timeIntervalSince(start)
    }
} 