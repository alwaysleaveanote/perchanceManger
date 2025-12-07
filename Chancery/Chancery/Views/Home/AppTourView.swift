//
//  AppTourView.swift
//  Chancery
//
//  Interactive tour of the app's features and capabilities.
//

import SwiftUI

/// A step in the app tour
struct TourStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let features: [TourFeature]
}

/// A feature highlight in a tour step
struct TourFeature {
    let icon: String
    let title: String
    let description: String
}

/// Full-screen app tour overlay
struct AppTourView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var currentStepIndex: Int = 0
    
    private let tourSteps: [TourStep] = [
        TourStep(
            title: "Welcome to Chancery",
            description: "Chancery helps you create, organize, and manage prompts for AI image generators like Perchance. Let's take a quick tour!",
            icon: "wand.and.stars",
            features: [
                TourFeature(icon: "square.and.pencil", title: "Build Prompts", description: "Create detailed prompts with structured sections"),
                TourFeature(icon: "person.3.fill", title: "Organize Characters", description: "Keep your characters and their images organized"),
                TourFeature(icon: "sparkles", title: "Generate Images", description: "Send prompts directly to Perchance generators")
            ]
        ),
        TourStep(
            title: "The Scratchpad",
            description: "The Scratchpad is your creative workspace. Build prompts using structured sections, then copy them or save them to characters.",
            icon: "square.and.pencil",
            features: [
                TourFeature(icon: "text.alignleft", title: "Structured Sections", description: "Physical description, outfit, pose, environment, lighting, and more"),
                TourFeature(icon: "doc.on.doc", title: "Copy & Generate", description: "One tap to copy your prompt or open the generator"),
                TourFeature(icon: "bookmark.fill", title: "Save Bookmarks", description: "Save prompts for later without assigning to a character"),
                TourFeature(icon: "person.badge.plus", title: "Add to Characters", description: "Save prompts directly to one or more character profiles")
            ]
        ),
        TourStep(
            title: "Character Profiles",
            description: "Create profiles for each character you work with. Each profile stores prompts, images, and can have its own visual theme.",
            icon: "person.crop.rectangle.stack",
            features: [
                TourFeature(icon: "person.circle", title: "Profile Pictures", description: "Set a profile image for easy identification"),
                TourFeature(icon: "doc.text.fill", title: "Multiple Prompts", description: "Store unlimited prompts per character"),
                TourFeature(icon: "photo.stack", title: "Image Gallery", description: "Attach generated images to each prompt"),
                TourFeature(icon: "paintpalette", title: "Custom Themes", description: "Give each character their own color scheme")
            ]
        ),
        TourStep(
            title: "Prompt Editor",
            description: "Each prompt has dedicated sections for different aspects of your image. Use presets to quickly fill in common values.",
            icon: "doc.text",
            features: [
                TourFeature(icon: "person.fill", title: "Physical Description", description: "Hair, eyes, body type, distinguishing features"),
                TourFeature(icon: "tshirt.fill", title: "Outfit & Pose", description: "What they're wearing and how they're positioned"),
                TourFeature(icon: "sun.max.fill", title: "Environment & Lighting", description: "Background setting and lighting conditions"),
                TourFeature(icon: "slider.horizontal.3", title: "Style & Technical", description: "Art style, quality settings, and negative prompts")
            ]
        ),
        TourStep(
            title: "Image Gallery",
            description: "Browse all your generated images in one place. View them full-screen, set profile pictures, or navigate to the prompt that created them.",
            icon: "photo.on.rectangle.angled",
            features: [
                TourFeature(icon: "hand.draw", title: "Swipe to Browse", description: "Swipe through images in full-screen view"),
                TourFeature(icon: "person.crop.circle.badge.checkmark", title: "Set as Profile", description: "Use any image as a character's profile picture"),
                TourFeature(icon: "arrow.right.circle", title: "Go to Prompt", description: "Jump directly to the prompt that created an image"),
                TourFeature(icon: "square.and.arrow.up", title: "Share Images", description: "Share your creations with others")
            ]
        ),
        TourStep(
            title: "Settings & Presets",
            description: "Save time with presets for common values, set global defaults, and personalize the app with different themes.",
            icon: "gearshape.fill",
            features: [
                TourFeature(icon: "paintbrush.fill", title: "App Themes", description: "Choose from multiple color themes for the app"),
                TourFeature(icon: "star.fill", title: "Presets", description: "Save and reuse common prompt sections"),
                TourFeature(icon: "text.badge.checkmark", title: "Global Defaults", description: "Set default values for new prompts"),
                TourFeature(icon: "link", title: "Generator Settings", description: "Configure your preferred Perchance generator")
            ]
        ),
        TourStep(
            title: "You're All Set!",
            description: "You now know the basics of Chancery. Start by creating a character or experimenting in the Scratchpad. Have fun!",
            icon: "checkmark.circle.fill",
            features: [
                TourFeature(icon: "sparkles", title: "Start Generating", description: "Head to the Scratchpad to create your first prompt"),
                TourFeature(icon: "person.badge.plus", title: "Create a Character", description: "Set up a profile for your first character"),
                TourFeature(icon: "questionmark.circle", title: "Need Help?", description: "You can always revisit this tour from the home screen"),
                TourFeature(icon: "heart.fill", title: "Enjoy!", description: "We hope Chancery helps you create amazing images")
            ]
        )
    ]
    
    private var currentStep: TourStep {
        tourSteps[currentStepIndex]
    }
    
    private var isFirstStep: Bool {
        currentStepIndex == 0
    }
    
    private var isLastStep: Bool {
        currentStepIndex == tourSteps.count - 1
    }
    
    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            ZStack {
                // Background
                theme.background.ignoresSafeArea()
                
                // Main content with swipe gesture
                ScrollView {
                    VStack(spacing: 24) {
                        // Step indicator
                        stepIndicator(theme: theme)
                        
                        // Screen preview (icon and title)
                        screenPreview(theme: theme)
                        
                        // Step content
                        stepContent(theme: theme)
                        
                        // Navigation buttons at bottom of scroll
                        navigationButtons(theme: theme)
                            .padding(.top, 8)
                    }
                    .padding()
                }
                .gesture(
                    DragGesture(minimumDistance: 50, coordinateSpace: .local)
                        .onEnded { value in
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height
                            
                            // Only respond to horizontal swipes
                            if abs(horizontalAmount) > abs(verticalAmount) {
                                if horizontalAmount < 0 && !isLastStep {
                                    // Swipe left - go to next
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentStepIndex += 1
                                    }
                                } else if horizontalAmount > 0 && !isFirstStep {
                                    // Swipe right - go to previous
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentStepIndex -= 1
                                    }
                                }
                            }
                        }
                )
            }
            .themedBackground()
            .navigationTitle("App Tour")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Step Indicator
    
    private func stepIndicator(theme: ResolvedTheme) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<tourSteps.count, id: \.self) { index in
                Circle()
                    .fill(index == currentStepIndex ? theme.primary : theme.primary.opacity(0.3))
                    .frame(width: index == currentStepIndex ? 10 : 8, height: index == currentStepIndex ? 10 : 8)
                    .animation(.easeInOut(duration: 0.2), value: currentStepIndex)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Screen Preview
    
    private func screenPreview(theme: ResolvedTheme) -> some View {
        VStack(spacing: 12) {
            // Icon with animated ring
            ZStack {
                // Outer ring
                Circle()
                    .stroke(theme.primary.opacity(0.2), lineWidth: 3)
                    .frame(width: 100, height: 100)
                
                // Inner filled circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.primary, theme.primary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: currentStep.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(theme.textOnPrimary)
            }
            .shadow(color: theme.primary.opacity(0.4), radius: 16, x: 0, y: 8)
            
            // Title
            Text(currentStep.title)
                .font(.title2.weight(.bold))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Step Content
    
    private func stepContent(theme: ResolvedTheme) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description
            Text(currentStep.description)
                .font(.body)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
            
            // Features grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(currentStep.features.indices, id: \.self) { index in
                    featureCard(feature: currentStep.features[index], theme: theme)
                }
            }
        }
    }
    
    // MARK: - Feature Card
    
    private func featureCard(feature: TourFeature, theme: ResolvedTheme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: feature.icon)
                    .font(.subheadline)
                    .foregroundColor(theme.primary)
                
                Text(feature.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
            }
            
            Text(feature.description)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .fill(theme.backgroundSecondary)
        )
    }
    
    // MARK: - Navigation Buttons
    
    private func navigationButtons(theme: ResolvedTheme) -> some View {
        HStack(spacing: 12) {
            // Back button
            if !isFirstStep {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStepIndex -= 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.medium))
                        Text("Back")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(theme.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                            .stroke(theme.primary, lineWidth: 1.5)
                    )
                }
            }
            
            Spacer()
            
            // Next/Finish button
            Button {
                if isLastStep {
                    dismiss()
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStepIndex += 1
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(isLastStep ? "Get Started" : "Next")
                        .font(.subheadline.weight(.semibold))
                    if !isLastStep {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .foregroundColor(theme.textOnPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [theme.primary, theme.primary.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
                .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
}
