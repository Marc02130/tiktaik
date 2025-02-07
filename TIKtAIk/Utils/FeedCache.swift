//
// FeedCache.swift
// TIKtAIk
//

import Foundation

actor FeedCache {
    private var cache: [String: (videos: [Video], timestamp: Date)] = [:]
    private let timeout: TimeInterval
    
    init(timeout: TimeInterval = 300) { // 5 minutes default
        self.timeout = timeout
    }
    
    func get(_ key: String) -> [Video]? {
        guard let entry = cache[key],
              Date().timeIntervalSince(entry.timestamp) < timeout else {
            return nil
        }
        return entry.videos
    }
    
    func set(_ key: String, videos: [Video]) {
        cache[key] = (videos, Date())
        scheduleCleanup(for: key)
    }
    
    private func scheduleCleanup(for key: String) {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            cache.removeValue(forKey: key)
        }
    }
    
    func remove(_ key: String) {
        cache.removeValue(forKey: key)
    }
} 