//
//  PromptPresetStore.swift
//  Chancery
//
//  Manages the storage and retrieval of prompt presets, global defaults,
//  and generator settings. Now backed by DataStore for CloudKit sync.
//

import Foundation
import SwiftUI
import Combine

// MARK: - PromptPresetStore

/// Central store for managing prompt presets, global defaults, and generator settings.
///
/// `PromptPresetStore` is an `ObservableObject` that provides:
/// - **Presets**: Reusable text snippets organized by prompt section
/// - **Global Defaults**: Default values applied to new prompts
/// - **Generator Settings**: The default Perchance generator to use
///
/// ## Data Persistence
/// Backed by `DataStore` which handles local persistence and CloudKit sync.
///
/// ## Usage
/// ```swift
/// @StateObject var presetStore = PromptPresetStore()
///
/// // Get presets for a section
/// let outfitPresets = presetStore.presets(of: .outfit)
///
/// // Add a new preset
/// presetStore.addPreset(kind: .pose, name: "Action Pose", text: "dynamic action pose")
/// ```
@MainActor
final class PromptPresetStore: ObservableObject {
    
    // MARK: - Private Properties
    
    private let dataStore = DataStore.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    /// All available presets across all section types
    @Published var presets: [PromptPreset] = []
    
    /// Global default values for each prompt section
    @Published var globalDefaults: [GlobalDefaultKey: String] = [:]
    
    /// The default Perchance generator slug to use
    @Published var defaultPerchanceGenerator: String = "ai-vibrant-image-generator"
    
    // MARK: - Initialization
    
    /// Creates a new preset store, syncing with DataStore
    init() {
        Logger.info("PromptPresetStore initializing with DataStore backing", category: .preset)
        
        // Sync with DataStore
        setupBindings()
    }
    
    // MARK: - DataStore Binding
    
    private func setupBindings() {
        // Observe DataStore changes and update local published properties
        dataStore.$presets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] presets in
                self?.presets = presets
            }
            .store(in: &cancellables)
        
        dataStore.$globalDefaults
            .receive(on: DispatchQueue.main)
            .sink { [weak self] defaults in
                self?.globalDefaults = defaults
            }
            .store(in: &cancellables)
        
        dataStore.$defaultPerchanceGenerator
            .receive(on: DispatchQueue.main)
            .sink { [weak self] generator in
                self?.defaultPerchanceGenerator = generator
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Preset Access
    
    /// Returns all presets for a specific section type
    /// - Parameter kind: The section type to filter by
    /// - Returns: Array of presets matching the section type
    func presets(of kind: PromptSectionKind) -> [PromptPreset] {
        presets.filter { $0.kind == kind }
    }
    
    /// Finds a preset by its ID
    /// - Parameter id: The preset's unique identifier
    /// - Returns: The preset if found, nil otherwise
    func preset(withId id: UUID) -> PromptPreset? {
        presets.first { $0.id == id }
    }
    
    // MARK: - Preset Management
    
    /// Adds or updates a preset
    ///
    /// If a preset with the same name and kind exists (case-insensitive),
    /// its text is updated. Otherwise, a new preset is created.
    ///
    /// - Parameters:
    ///   - kind: The section type for the preset
    ///   - name: The display name for the preset
    ///   - text: The preset content
    func addPreset(kind: PromptSectionKind, name: String, text: String) {
        dataStore.addPreset(kind: kind, name: name, text: text)
    }
    
    /// Removes a preset by its ID
    /// - Parameter id: The preset's unique identifier
    /// - Returns: True if a preset was removed, false if not found
    @discardableResult
    func removePreset(withId id: UUID) -> Bool {
        guard let preset = presets.first(where: { $0.id == id }) else {
            Logger.warning("Attempted to remove non-existent preset: \(id)", category: .preset)
            return false
        }
        
        dataStore.deletePreset(preset)
        return true
    }
    
    // MARK: - Global Defaults
    
    /// Gets the global default value for a section
    /// - Parameter key: The section key
    /// - Returns: The default value, or nil if not set
    func globalDefault(for key: GlobalDefaultKey) -> String? {
        globalDefaults[key]
    }
    
    /// Sets the global default value for a section
    /// - Parameters:
    ///   - value: The new default value (nil to clear)
    ///   - key: The section key
    func setGlobalDefault(_ value: String?, for key: GlobalDefaultKey) {
        dataStore.setGlobalDefault(value, for: key)
    }
    
    /// Sets the default generator
    /// - Parameter generator: The generator slug
    func setDefaultGenerator(_ generator: String) {
        dataStore.setDefaultGenerator(generator)
    }
}

// MARK: - Sample Data

extension PromptPresetStore {
    
    /// Sample presets for initial app state
    static let samplePresets: [PromptPreset] = [
        // Outfit presets
        PromptPreset(kind: .outfit, name: "Casual Outfit", text: "hoodie, jeans, sneakers, relaxed casual style"),
        PromptPreset(kind: .outfit, name: "Fantasy Armor", text: "ornate plate armor, engraved runes, flowing cape"),
        
        // Pose presets
        PromptPreset(kind: .pose, name: "Hero Pose", text: "standing tall, chest out, confident stance, looking at viewer"),
        PromptPreset(kind: .pose, name: "Relaxed Sitting", text: "sitting cross-legged, relaxed shoulders, soft expression"),
        
        // Environment presets
        PromptPreset(kind: .environment, name: "Cozy Room", text: "warm cozy bedroom, soft blankets, fairy lights, bookshelves"),
        PromptPreset(kind: .environment, name: "Sci-Fi Lab", text: "sleek futuristic lab, holographic screens, glowing consoles"),
        
        // Lighting presets - comprehensive options
        PromptPreset(kind: .lighting, name: "Golden Hour", text: "golden hour lighting, warm orange and amber tones, sun low on horizon, long soft shadows, lens flare, magical hour, warm color temperature, backlit subject, glowing highlights"),
        PromptPreset(kind: .lighting, name: "Studio Portrait", text: "professional studio lighting setup, three-point lighting, key light with soft fill light, rim light separation, softbox diffusion, even illumination, no harsh shadows, controlled lighting environment"),
        PromptPreset(kind: .lighting, name: "Dramatic Rim", text: "dramatic rim lighting, strong backlight creating silhouette edges, high contrast chiaroscuro, moody atmosphere, dark shadows, glowing outline, cinematic lighting, volumetric light rays"),
        PromptPreset(kind: .lighting, name: "Soft Natural", text: "soft diffused natural daylight, overcast sky lighting, gentle shadows, flattering skin tones, even ambient light, no harsh highlights, natural color balance, outdoor shade lighting"),
        PromptPreset(kind: .lighting, name: "Neon Cyberpunk", text: "neon lighting, vibrant pink and cyan color cast, electric blue and magenta glow, reflective wet surfaces, urban night atmosphere, holographic reflections, LED accent lights, futuristic city glow"),
        PromptPreset(kind: .lighting, name: "Candlelight", text: "warm candlelight illumination, flickering orange and amber glow, intimate romantic atmosphere, soft dancing shadows, low-key lighting, warm color temperature, cozy ambiance, fire glow"),
        PromptPreset(kind: .lighting, name: "Moonlight", text: "cool moonlight illumination, blue-silver ethereal tones, night atmosphere, subtle soft shadows, starlight, nocturnal ambiance, cool color temperature, mystical glow"),
        PromptPreset(kind: .lighting, name: "Window Light", text: "natural window light from side, soft directional indoor lighting, Rembrandt lighting pattern, gentle shadows on opposite side, ambient room fill, diffused daylight through curtains"),
        
        // Style presets - diverse artistic styles
        PromptPreset(kind: .style, name: "Photorealistic", text: "photorealistic rendering, hyperrealistic detail, lifelike appearance, natural skin texture and pores, realistic material properties, physically accurate lighting, indistinguishable from photograph, ultra-realistic"),
        PromptPreset(kind: .style, name: "Digital Painting", text: "digital painting style, painterly brushstrokes visible, rich saturated color palette, artistic interpretation, professional digital art, trending on artstation, detailed illustration, masterful technique"),
        PromptPreset(kind: .style, name: "Anime/Manga", text: "anime art style, manga aesthetic, clean crisp lineart, cel-shaded flat coloring, large expressive eyes, Japanese animation style, vibrant colors, dynamic poses, studio quality anime"),
        PromptPreset(kind: .style, name: "Oil Painting", text: "classical oil painting style, old masters technique, rich impasto textures, museum quality fine art, Renaissance influence, visible canvas texture, glazing layers, timeless masterpiece quality"),
        PromptPreset(kind: .style, name: "Watercolor", text: "traditional watercolor painting, soft bleeding edges, transparent color washes, wet-on-wet technique, delicate paper texture, artistic color bleeding, loose expressive style, luminous transparency"),
        PromptPreset(kind: .style, name: "Comic Book", text: "comic book illustration style, bold black ink outlines, halftone dot shading, dynamic action composition, graphic novel aesthetic, pop art influence, vibrant flat colors, sequential art style"),
        PromptPreset(kind: .style, name: "3D Render", text: "3D CGI render, photorealistic CGI, subsurface scattering on skin, ray traced global illumination, Octane render engine, Unreal Engine 5 quality, physically based rendering, studio lighting setup"),
        PromptPreset(kind: .style, name: "Concept Art", text: "professional concept art, entertainment design illustration, trending on artstation and deviantart, industry standard quality, detailed environment and character design, visual development art"),
        PromptPreset(kind: .style, name: "Fantasy Art", text: "epic fantasy art illustration, magical atmosphere with particle effects, detailed fantasy world building, dramatic composition, enchanted lighting, mythical aesthetic, book cover quality"),
        PromptPreset(kind: .style, name: "Vintage Photo", text: "vintage photograph aesthetic, authentic film grain texture, faded muted colors, retro color grading, nostalgic 1970s feel, aged photo quality, slight vignette, analog camera look"),
        
        // Technical presets - quality and camera settings
        PromptPreset(kind: .technical, name: "Ultra HD", text: "8k UHD resolution, ultra-detailed rendering, extremely sharp focus throughout, high definition clarity, intricate fine details visible, maximum quality output, professional grade"),
        PromptPreset(kind: .technical, name: "Portrait Depth", text: "shallow depth of field, wide aperture f/1.4 to f/2.8, beautiful creamy bokeh background, subject tack sharp in focus, blurred background separation, portrait lens compression, 85mm equivalent"),
        PromptPreset(kind: .technical, name: "Wide Angle", text: "wide angle lens perspective, 24mm focal length equivalent, expansive environmental context, slight barrel distortion, dramatic foreground to background scale, architectural photography style"),
        PromptPreset(kind: .technical, name: "Cinematic", text: "cinematic film composition, 35mm motion picture film look, anamorphic lens characteristics with oval bokeh, 2.39:1 aspect ratio feel, movie still quality, color graded, theatrical lighting"),
        PromptPreset(kind: .technical, name: "Macro Detail", text: "macro photography extreme close-up, intricate microscopic details visible, razor sharp focus plane, professional macro lens, detailed texture capture, scientific precision"),
        PromptPreset(kind: .technical, name: "Professional Photo", text: "professional photography quality, full-frame DSLR camera, perfect exposure and white balance, accurate color reproduction, editorial quality, magazine cover worthy, studio professional"),
        PromptPreset(kind: .technical, name: "Soft Aesthetic", text: "soft focus dreamy atmosphere, gentle gaussian blur, ethereal glowing quality, diffused lighting, romantic soft-focus lens effect, hazy dreamlike ambiance, pastel tones"),
        PromptPreset(kind: .technical, name: "High Contrast", text: "high contrast dramatic look, deep rich blacks, bright clean highlights, punchy vibrant saturated colors, bold tonal range, striking visual impact, vivid color pop"),
        
        // Negative presets - common issues to avoid
        PromptPreset(kind: .negative, name: "Standard Quality", text: "blurry, out of focus, low quality, low resolution, pixelated, jpeg artifacts, compression artifacts, noise, grainy, poorly rendered, amateur quality"),
        PromptPreset(kind: .negative, name: "Anatomy Fixes", text: "bad anatomy, wrong anatomy, extra limbs, missing limbs, floating limbs, disconnected limbs, deformed hands, extra fingers, fused fingers, too many fingers, missing fingers, mutated hands, malformed limbs"),
        PromptPreset(kind: .negative, name: "Face Fixes", text: "deformed face, ugly face, disfigured features, bad eyes, crossed eyes, asymmetrical eyes, lazy eye, asymmetrical face, distorted facial features, uncanny valley, weird expression, mutation"),
        PromptPreset(kind: .negative, name: "Clean Output", text: "watermark, signature, text overlay, logo, username, artist name, copyright notice, website URL, banner, title, caption, label, stamp, border"),
        PromptPreset(kind: .negative, name: "Composition", text: "cropped awkwardly, out of frame, cut off at edges, bad framing, poorly composed, off-center subject, cluttered background, distracting elements, unbalanced composition"),
        PromptPreset(kind: .negative, name: "Full Negative", text: "blurry, low quality, bad anatomy, extra limbs, deformed, disfigured, ugly, mutation, watermark, text, signature, cropped, worst quality, low resolution, jpeg artifacts, error, duplicate"),
        PromptPreset(kind: .negative, name: "Realistic Negative", text: "cartoon, anime, illustration, painting, drawing, sketch, artwork, cgi, 3d render, digital art, unrealistic, stylized, artistic interpretation, non-photographic"),
        PromptPreset(kind: .negative, name: "Anime Negative", text: "realistic, photorealistic, photograph, 3d render, western cartoon style, bad proportions, off-model, inconsistent style, wrong art style, semi-realistic")
    ]
    
    /// Sample global defaults for initial app state
    static let sampleDefaults: [GlobalDefaultKey: String] = [
        .outfit: "",
        .pose: "",
        .environment: "",
        .lighting: "soft natural lighting",
        .style: "high quality, detailed",
        .technical: "sharp focus, high resolution",
        .negative: "blurry, low quality, bad anatomy, extra limbs, watermark, text"
    ]
}
