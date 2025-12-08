//
//  OverviewCardProtocol.swift
//  Chancery
//
//  Protocol defining shared behavior for Character and Scene overview data.
//

import Foundation

/// Protocol for entities that can be displayed in an overview card (Character or Scene)
protocol OverviewCardDataSource: Identifiable {
    var id: UUID { get }
    var name: String { get set }
    var profileImageData: Data? { get set }
    var links: [RelatedLink] { get set }
    var standaloneImages: [PromptImage] { get set }
    var allImages: [PromptImage] { get }
    
    /// The theme ID for this entity (characterThemeId or sceneThemeId)
    var themeId: String? { get }
}

// MARK: - CharacterProfile Conformance

extension CharacterProfile: OverviewCardDataSource {
    var themeId: String? { characterThemeId }
}

// MARK: - CharacterScene Conformance

extension CharacterScene: OverviewCardDataSource {
    var themeId: String? { sceneThemeId }
}
