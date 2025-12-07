//
//  FeatureFlags.swift
//  Chancery
//
//  Feature flags for enabling/disabling features during development.
//

import Foundation

// MARK: - Feature Flags

/// Central location for feature flags
enum FeatureFlags {
    
    /// Whether CloudKit sync is enabled.
    /// Set to `false` while Apple Developer account is provisioning.
    /// Set to `true` once CloudKit container is properly configured.
    static let isCloudKitEnabled = false
    
}
