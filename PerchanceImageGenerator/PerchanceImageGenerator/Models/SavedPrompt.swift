import Foundation

/// A saved prompt with all section fields and preset markers
struct SavedPrompt: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var text: String

    var physicalDescription: String?
    var outfit: String?
    var pose: String?
    var environment: String?
    var lighting: String?
    var styleModifiers: String?
    var technicalModifiers: String?
    var negativePrompt: String?
    var additionalInfo: String?

    var physicalDescriptionPresetName: String?
    var outfitPresetName: String?
    var posePresetName: String?
    var environmentPresetName: String?
    var lightingPresetName: String?
    var stylePresetName: String?
    var technicalPresetName: String?
    var negativePresetName: String?

    var images: [PromptImage] = []

    init(
        title: String,
        text: String,
        physicalDescription: String? = nil,
        outfit: String? = nil,
        pose: String? = nil,
        environment: String? = nil,
        lighting: String? = nil,
        styleModifiers: String? = nil,
        technicalModifiers: String? = nil,
        negativePrompt: String? = nil,
        additionalInfo: String? = nil,
        physicalDescriptionPresetName: String? = nil,
        outfitPresetName: String? = nil,
        posePresetName: String? = nil,
        environmentPresetName: String? = nil,
        lightingPresetName: String? = nil,
        stylePresetName: String? = nil,
        technicalPresetName: String? = nil,
        negativePresetName: String? = nil,
        images: [PromptImage] = []
    ) {
        self.title = title
        self.text = text
        self.physicalDescription = physicalDescription
        self.outfit = outfit
        self.pose = pose
        self.environment = environment
        self.lighting = lighting
        self.styleModifiers = styleModifiers
        self.technicalModifiers = technicalModifiers
        self.negativePrompt = negativePrompt
        self.additionalInfo = additionalInfo

        self.physicalDescriptionPresetName = physicalDescriptionPresetName
        self.outfitPresetName = outfitPresetName
        self.posePresetName = posePresetName
        self.environmentPresetName = environmentPresetName
        self.lightingPresetName = lightingPresetName
        self.stylePresetName = stylePresetName
        self.technicalPresetName = technicalPresetName
        self.negativePresetName = negativePresetName
        self.images = images
    }
}
