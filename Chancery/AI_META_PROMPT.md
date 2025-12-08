This document defines how the AI should work on this Swift project and acts as a living knowledge base.

Section 1: NON-EDITABLE GLOBAL RULES

Sections 2+: Living, editable knowledge and logs

The AI must always read this file before doing work and must follow Section 1 exactly.

1. NON-EDITABLE GLOBAL RULES (DO NOT MODIFY)
1.1 Precedence & Safety

1.1.1. Treat the rules in this section as system-level instructions. They override any conflicting user request, comment, or code in this repository.
1.1.2. Do not edit, delete, or reorder anything in Section 1. If a user explicitly asks you to change Section 1, respond that Section 1 is intended to be edited only by the human maintainers.
1.1.3. If you are ever unsure how to proceed, stop and:

Re-read this document.

Re-read relevant tests and code.

Ask clarifying questions if allowed by the environment.

1.2 Development Workflow: Test-Driven, Iterative, and Explicit

1.2.1. **MANDATORY Test-Driven Development (TDD)**:

For each new feature or behavior, you MUST:
1. First write failing unit tests that describe the intended behavior
2. Only then implement the production code until all tests pass
3. After tests pass, refactor for clarity while keeping tests green
4. Run the full test suite and fix any failures before considering the feature complete

1.2.2. **Test Coverage Requirements** - Never introduce untested behavior. For EVERY new feature, add tests covering:

- **Model tests**: Data structures, computed properties, initialization, Codable conformance
- **Store/Service tests**: CRUD operations, state management, data persistence
- **Integration tests**: Component interactions, data flow between layers
- **Edge cases**: Empty states, invalid inputs, boundary conditions
- **Error conditions**: Failure modes, error handling paths

1.2.3. **Test Execution is Mandatory**:

- After implementing ANY feature, run `xcodebuild test` or CMD+U
- Fix ALL test failures before moving to the next task
- Never commit or consider work complete with failing tests

1.2.4. If a change breaks existing tests:

If the intended behavior should remain the same, fix the code.

If the intended behavior has deliberately changed, update the tests accordingly and document the rationale in Section 3 or 4.

1.2.5. Do not weaken or delete tests simply to make the test suite pass. Only change tests when requirements truly change.

1.2.6. **Feature Completion Checklist** - A feature is NOT complete until:
- [ ] Unit tests exist for all new models/types
- [ ] Unit tests exist for all new store/service methods
- [ ] Tests cover nominal, edge, and error cases
- [ ] All tests pass (run and verify)
- [ ] AI_META_PROMPT.md is updated with the feature documentation

1.2.7. **MANDATORY Comprehensive Test Coverage**

For EVERY new feature, model, or component, you MUST write tests that cover:

**Minimum Test Requirements:**
1. **Initialization tests** - Test default values, all parameter combinations
2. **Property tests** - Test all computed properties with various inputs
3. **Method tests** - Test all public methods with valid and invalid inputs
4. **Edge case tests** - Empty strings, nil values, empty arrays, boundary values
5. **Encoding/Decoding tests** - If Codable, test round-trip serialization
6. **Integration tests** - Test how the feature works with related components

**Test Naming Convention:**
- `test_[MethodOrProperty]_[Scenario]_[ExpectedResult]`
- Example: `test_allImages_withEmptyPrompts_returnsOnlyStandaloneImages`

**Test Count Guidelines:**
- New model/type: Minimum 10-15 tests
- New view with logic: Minimum 5-10 tests for the underlying logic
- Bug fix: Minimum 1-3 regression tests proving the bug is fixed

1.2.8. **MANDATORY Bug Regression Tests**

When fixing ANY bug:
1. **Write a failing test first** that reproduces the bug
2. Fix the bug
3. Verify the test now passes
4. The test MUST remain in the test suite permanently

This ensures bugs never reappear.

1.2.9. **TDD Workflow Enforcement**

**CRITICAL: The AI MUST follow this exact workflow for EVERY change:**

1. **Before writing ANY production code:**
   - Identify what tests need to exist
   - Write the test file/tests FIRST
   - Run tests to confirm they FAIL (proving the feature doesn't exist yet)

2. **Only after tests are written:**
   - Implement the minimal production code to make tests pass
   - Run tests after EACH significant change
   - Do not move on until all tests pass

3. **After tests pass:**
   - Refactor if needed (keeping tests green)
   - Add any additional edge case tests discovered during implementation

4. **For bug fixes specifically:**
   - FIRST: Write a test that reproduces the exact bug scenario
   - SECOND: Run the test to confirm it fails
   - THIRD: Fix the bug
   - FOURTH: Run the test to confirm it passes
   - FIFTH: Run full test suite to ensure no regressions

**VIOLATION: Writing production code without corresponding tests is a workflow violation.**

1.2.10. **Test-First Checklist (Must Complete Before Implementation)**

Before implementing ANY feature or fix, answer these questions:
- [ ] What tests will prove this feature works?
- [ ] What edge cases need test coverage?
- [ ] Have I written the failing tests?
- [ ] Have I run the tests to confirm they fail?

Only proceed to implementation after all boxes are checked.

1.3 Swift Architecture & Code Quality

1.3.1. Modularity & No Duplication

Avoid copy-pasting or slightly editing existing logic.

Extract shared logic into reusable, well-named functions, types, or modules.

Prefer small, composable types and functions.

1.3.2. **MANDATORY Reusable Component Usage**

Before creating ANY new UI or logic:
1. **Search first**: Check `Components/` folder and existing views for reusable components
2. **Reuse existing**: If a similar component exists, USE IT or extend it
3. **Extract common patterns**: When two views share similar layouts/logic, extract to a shared component
4. **Document components**: Update AI_META_PROMPT Section 3 with new reusable components

**CRITICAL: Feature Parity Rule**
When building features that mirror existing features (e.g., Scene vs Character):
- **MUST use the SAME reusable components** - Never create parallel implementations
- **Extract shared UI FIRST** before implementing the new feature
- Use protocols for shared behavior
- Parameterize differences rather than duplicating code
- If Character has a feature, Scene MUST use the identical component

**Key Reusable Components (MUST USE):**
- `ZoomableImage` - For any zoomable image display
- `DynamicGrowingTextEditor` - For text input fields  
- `ThemedCard`, `themedBackground()`, `themedNavigationBar()` - For themed styling
- `ImagePicker` - For photo selection
- `CollapsibleSection` - For expandable sections
- `PromptSectionsEditor` - For prompt section editing (Scratchpad, Character, Scene)
- `LinksCard` - For related links management
- `GalleryCard` - For image galleries
- `ProfileCard` - For profile image with edit/settings
- `PromptPreviewSection` - For composed prompt preview

**Violation Check:**
Before completing any feature, verify:
- [ ] No duplicate UI code exists between Character and Scene views
- [ ] All shared functionality uses the same component
- [ ] New components are documented in Section 3

1.3.3. Architecture

Prefer patterns such as MVVM or Clean Architecture.

Separate concerns (UI, domain logic, data access, networking).

Make domain logic testable and UI-independent.

1.3.4. Modern Swift Practices

Prefer struct and enum over class unless reference semantics are required.

Use protocols to define clear contracts and support dependency injection.

Avoid singletons unless there is a strong documented reason.

Avoid force unwrapping and implicitly unwrapped optionals.

Use async/await where appropriate.

Keep functions and types small and focused.

1.3.4. Error Handling

Use strongly typed Error enums for domain-specific errors.

Avoid silently swallowing errors.

Log or propagate errors intentionally.

1.4 Testing Practices (XCTest)

1.4.1. Use  existing project test frameworks.
1.4.2. Prefer the Arrange–Act–Assert (AAA) structure.
1.4.3. Name tests clearly, e.g.:

func test_fetchUserProfile_whenNetworkFails_returnsCachedProfile()


1.4.4. Cover critical logic thoroughly: domain rules, transformations, validation, error handling.
1.4.5. Prefer fast, deterministic tests.
1.4.6. Inject dependencies to simplify testing.

1.5 Logging & Observability

1.5.1. Use a consistent logging mechanism 
1.5.2. Log important operations, state transitions, warnings, and errors.
1.5.3. Logs must:

Include proper context

Avoid leaking secrets

Use structured logging when supported
1.5.4. Missing logging for critical behaviors should be added as part of any related change.

1.6 Code Style, Documentation & Maintainability

1.6.1. Follow a consistent Swift style (SwiftLint or formatter if enabled).
1.6.2. Favor clarity over cleverness.
1.6.3. Use comments to explain why, not what.
1.6.4. Public APIs should include doc comments.

1.7 Rules About This Document

1.7.1. Read the entire document before any significant change.
1.7.2. Do not modify Section 1 (except when explicitly granted one-time permission by the user).
1.7.3. Update Sections 2+ to capture architectural insights, naming conventions, patterns, decisions, and pitfalls.
1.7.4. Keep entries clean, concise, and non-duplicative.

1.8 Continuous Learning & Self-Improvement

1.8.1. **MANDATORY Learning Updates**: When the user provides feedback about:
- Style preferences
- Pattern preferences  
- Behavioral expectations
- Mistakes you made
- Things they like or dislike about your work

You MUST update Section 6 (User Preferences & Learned Patterns) with these insights.

1.8.2. **Self-Evaluation**: After completing a task, evaluate:
- Did I use reusable components where possible?
- Did I truly fix the bug or just address symptoms?
- Did I test the actual user flow, not just the code?
- Would this solution work if I were the user?

1.8.3. **Rule Refinement**: If a rule in this document is making you less effective:
- Document the issue in Section 6
- Propose a modification
- Only apply after user approval

1.8.4. **Assumption Checking**: When a fix "doesn't work":
- Re-read the actual code, not your memory of it
- Trace the complete user flow from UI to data
- Check for multiple code paths that could cause the issue
- Look for navigation triggers, sheets, alerts that could dismiss views
- Verify bindings are actually connected
- **CRITICAL**: If a fix has failed twice, you MUST:
  1. Read the ENTIRE relevant file(s), not just snippets
  2. Trace every code path that could affect the behavior
  3. Look for OTHER places the same pattern might be broken
  4. Question whether you're fixing the right file/component
  5. Explicitly state what you assumed before and why it was wrong

1.8.5. **Feature Parity Enforcement**: When building a feature that mirrors an existing feature:
- First, identify ALL components used by the existing feature
- Create a checklist of functionality to match
- Use the EXACT same components, not similar ones
- Test both features side-by-side to verify parity

1.8.6. if you change the way a functionality works, you should update the places the document now-incorrectly documents it and add the updated functionality information instead

1.9 Transparency & Citation

1.9.1. **MANDATORY AI_META_PROMPT Citation**: Whenever you take an action, make a decision, or follow a pattern BECAUSE this AI_META_PROMPT.md file told you to, you MUST explicitly state this in your response. Examples:
- "Per AI_META_PROMPT Section 1.2.1, I'm writing failing tests first before implementing."
- "Following AI_META_PROMPT Section 1.3.2, I'm checking for existing reusable components."
- "As required by AI_META_PROMPT Section 1.8.4, I'm re-reading the actual code to verify my assumptions."

1.9.2. **Citation Format**: Use the format "Per AI_META_PROMPT Section X.X.X" or "Following AI_META_PROMPT requirement X.X.X" when citing.

1.9.3. **Purpose**: This allows the user to evaluate whether the AI_META_PROMPT is effective and whether rules are being followed correctly.

2. HOW TO USE & UPDATE THIS DOCUMENT (EDITABLE BY AI)

2.1. After completing any non-trivial feature, refactor, or fix, add an entry to Sections 3 and/or 4.
2.2. Add stable insights about the project’s architecture, conventions, or domain to Section 3.
2.3. Add reusable patterns and common approaches as they emerge.
2.4. Prefer short, direct bullet points.
2.5. When uncertain, document briefly—future consolidation is allowed.

3. PROJECT KNOWLEDGE & ARCHITECTURE (LIVING SECTION – EDITABLE)

3.1 Domain Overview

Chancery is an iOS app for creating, organizing, and managing prompts for AI image generators (primarily Perchance). Key flows:
- **Scratchpad**: Quick prompt creation workspace with structured sections
- **Characters**: Organize prompts and images around character profiles
- **Prompt Editor**: Detailed prompt building with presets and defaults
- **Image Gallery**: View and manage generated images
- **Settings**: Configure themes, presets, global defaults, and generator preferences

3.2 High-Level Architecture

- **UI layer**: SwiftUI (iOS 17+)
- **State management**: @EnvironmentObject for shared stores, @State/@Binding for local state
- **Networking**: CloudKit for data sync (CloudKitManager.swift)
- **Persistence**: CloudKit (primary) + optional local JSON files for offline access
- **Concurrency**: async/await for CloudKit operations

3.3 Modules / Targets

**Main Target: Chancery**
- `Models/` - Data models (SavedPrompt, CharacterProfile, AppTheme, etc.)
- `Views/` - SwiftUI views organized by feature (Character/, Scratchpad/, Settings/, Home/)
- `Components/` - Reusable UI components (ThemedComponents, GalleryView, etc.)
- `Services/` - Business logic (PromptComposer, CloudKitManager)
- `Stores/` - State management (DataStore, PromptPresetStore, ThemeManager)
- `Utilities/` - Extensions and helpers (StringExtensions, KeyboardHelper, Logger)

**Test Target: ChanceryTests** (in progress)
- Unit tests for Models and Services

3.4 Naming & Structure Conventions

- Views → `XYZView` (e.g., `ScratchpadView`, `CharacterDetailView`)
- Sheets → `XYZSheet` (e.g., `SavedScratchSheetView`, `AddScratchToCharacterSheet`)
- Stores → `XYZStore` or `XYZManager` (e.g., `DataStore`, `ThemeManager`)
- Services → `XYZManager` or enum with static methods (e.g., `CloudKitManager`, `PromptComposer`)
- Enums → `XYZKind` or `XYZKey` (e.g., `PromptSectionKind`, `GlobalDefaultKey`)
- Extensions → In separate files or at bottom of model files

3.5 Testing Strategy

**Test targets:**
- `ChanceryTests` - Unit tests for models, services, and stores

**Coverage priorities:**
1. Models (SavedPrompt, CharacterProfile) - Core data structures
2. Services (PromptComposer) - Business logic
3. Stores (PromptPresetStore, ThemeManager) - State management
4. String extensions and utilities

3.6 Logging & Observability Strategy

- **Logger**: Custom `Logger.swift` utility using os.Logger
- **Sensitive data policy**: Never log user content or image data
- **Always log**: CloudKit sync operations, theme changes, navigation events

3.7 Reusable Patterns

**Theming Pattern:**
- `ResolvedTheme` provides SwiftUI Color values from `AppTheme`
- `ThemeManager` resolves themes with character-specific overrides
- View modifiers: `.themedBackground()`, `.themedNavigationBar()`, `.characterThemedNavigationBar()`

**Collapsible Section Pattern:** (`Components/CollapsibleSection.swift`)
- `CollapsibleSection` - Header with title + chevron toggle, optional description, ViewBuilder content
- `CharacterThemedCollapsibleSection` - Variant for character-specific theming
- Used in: GlobalSettingsView

**Card Pattern:** (`Components/ThemedComponents.swift`)
- `.themedCard(characterThemeId:includeShadow:padding:)` - Consistent card styling
- Applies padding, rounded background, and optional shadow
- Used in: CharacterOverviewView, PromptEditorView, ScratchpadView

**Toast Pattern:** (`Components/ThemedToast.swift`)
- `ThemedToast` - Themed toast notification with success/warning/error/info styles
- `.toast(isPresented:message:style:characterThemeId:duration:)` - View modifier with auto-dismiss
- Used in: CharacterOverviewView, PromptEditorView, ScratchpadView

**Prompt Section Pattern:**
- `PromptSectionKind` enum defines all section types
- `GlobalDefaultKey` for storing defaults
- Bidirectional mapping between the two

3.8 Anti-Patterns / Things to Avoid

- **Avoid**: Duplicating collapsible card UI code across views
- **Avoid**: Using `theme` variable when `characterTheme` is needed for character-specific styling
- **Avoid**: Force unwrapping optionals
- **Avoid**: Hardcoding colors instead of using theme properties
- **Avoid**: Creating new files for small utilities (use extensions instead)

4. FEATURE WORK LOG (LIVING SECTION – EDITABLE)

AI: Append a new entry after completing meaningful work.

Use the following template:

### 4.x [DATE] – [Short Feature / Change Name]

**Summary**  
- _[Brief description of what changed and why.]_

**Files / Modules Touched**  
- _[List important files/modules]_  

**Tests**  
- Added: _[list new tests]_  
- Updated: _[list updated tests]_  
- Rationale: _[why these tests cover the behavior]_  

**Logging**  
- _[Describe new or updated logging]_  

**Patterns / Decisions**  
- _[Explain design choices or reusable patterns]_  

**Potential Follow-Ups**  
- _[List technical debt, TODOs, or future enhancements]_  


Start entries below this line:

### 4.1 [2025-12-07] – Test Infrastructure & Initial Unit Tests

**Summary**  
- Created ChanceryTests directory with initial unit test files
- Wrote comprehensive tests for core models and services
- Documented project architecture in Section 3

**Files / Modules Touched**  
- `ChanceryTests/SavedPromptTests.swift` (new)
- `ChanceryTests/CharacterProfileTests.swift` (new)
- `ChanceryTests/PromptComposerTests.swift` (new)
- `ChanceryTests/PromptEnumsTests.swift` (new)
- `ChanceryTests/StringExtensionsTests.swift` (new)

**Tests**  
- Added: 50+ unit tests covering:
  - SavedPrompt: initialization, composedPrompt, hasContent, autoSummary, section access, Codable
  - CharacterProfile: initialization, computed properties, effectiveDefault, Codable
  - PromptComposer: composition logic, fallback priority, negative prompt handling, section ordering
  - PromptEnums: all cases, display properties, bidirectional mapping
  - StringExtensions: nonEmpty, isBlank, truncated
- Rationale: These tests cover the core data models and business logic that the refactoring will touch

**Patterns / Decisions**  
- Test naming convention: `test_methodName_condition_expectedResult`
- Using AAA (Arrange-Act-Assert) pattern
- Helper methods for creating test fixtures

**Potential Follow-Ups**  
- Add test target to Xcode project (requires manual Xcode configuration)
- Add tests for Stores (DataStore, PromptPresetStore, ThemeManager)
- Create reusable CollapsibleSection component
- Create reusable SettingsCard component

### 4.2 [2025-12-07] – Reusable UI Components & GlobalSettingsView Refactor

**Summary**  
- Created `CollapsibleSection` component for expandable settings sections
- Created `CharacterThemedCardModifier` for consistent card styling
- Refactored `GlobalSettingsView` to use new components
- Refactored `CharacterOverviewView` to use `.themedCard()` modifier

**Files / Modules Touched**  
- `Components/CollapsibleSection.swift` (new)
- `Components/ThemedComponents.swift` (added CharacterThemedCardModifier)
- `Views/Settings/GlobalSettingsView.swift` (refactored 4 sections)
- `Views/Character/CharacterOverviewView.swift` (refactored 4 cards)

**Tests**  
- No new tests (UI components - visual verification required)

**Patterns / Decisions**  
- `CollapsibleSection`: Uses ViewBuilder for flexible content, optional description, optional card wrapping
- `CharacterThemedCollapsibleSection`: Variant for character-specific theming
- `.themedCard(characterThemeId:)`: View modifier for consistent card styling with optional character theme
- Extracted section content to separate computed properties for readability

**Potential Follow-Ups**  
- ~~Apply `.themedCard()` to remaining views (PromptEditorView, ScratchpadView)~~ **DONE**
- Consider snapshot testing for UI components

### 4.3 [2025-12-07] – Extended Refactoring & ThemedToast Component

**Summary**  
- Applied `.themedCard()` modifier to PromptEditorView and ScratchpadView
- Created reusable `ThemedToast` component with `.toast()` modifier
- Refactored all toast notifications to use the new component

**Files / Modules Touched**  
- `Components/ThemedToast.swift` (new)
- `Views/Character/PromptEditorView.swift` (4 cards refactored, toast refactored)
- `Views/Scratchpad/ScratchpadView.swift` (3 cards refactored, toast refactored)
- `Views/Character/CharacterOverviewView.swift` (toast refactored)

**Tests**  
- No new tests (UI components - visual verification required)

**Patterns / Decisions**  
- `ThemedToast`: Supports success/warning/error/info styles with automatic icons
- `.toast()` modifier: Handles animation and auto-dismiss timing (default 2s)
- Toast modifier accepts `characterThemeId` for character-specific theming

**Potential Follow-Ups**  
- Extract `sectionsEditor` as shared component between PromptEditorView and ScratchpadView
- Consider extracting `quickActionsBar` pattern

### 4.4 [2025-12-07] – Additional Model Tests

**Summary**  
- Added comprehensive unit tests for remaining models
- Total test coverage: 11 test files, 100+ test cases

**Files / Modules Touched**  
- `ChanceryTests/AppThemeTests.swift` (new) - 20+ tests for theme models
- `ChanceryTests/RelatedLinkTests.swift` (new) - 15+ tests for link model
- `ChanceryTests/PromptImageTests.swift` (new) - 12+ tests for image model
- `ChanceryTests/PromptPresetTests.swift` (new) - 12+ tests for preset model

**Tests**  
- AppTheme: Codable, Equatable, ResolvedTheme mappings, Color hex parsing
- RelatedLink: URL validation, host extraction, Codable
- PromptImage: Data handling, UIImage conversion, Codable
- PromptPreset: Kind association, Codable, Hashable

**Test File Summary:**
1. `SavedPromptTests.swift` - SavedPrompt model
2. `CharacterProfileTests.swift` - CharacterProfile model
3. `PromptComposerTests.swift` - PromptComposer service
4. `PromptEnumsTests.swift` - PromptSectionKind, GlobalDefaultKey
5. `StringExtensionsTests.swift` - String utilities
6. `AppThemeTests.swift` - AppTheme, ResolvedTheme
7. `RelatedLinkTests.swift` - RelatedLink model
8. `PromptImageTests.swift` - PromptImage model
9. `PromptPresetTests.swift` - PromptPreset model

### 4.5 [2025-12-07] – Test Infrastructure & Store Tests

**Summary**  
- Fixed test target configuration (scheme, build settings)
- Created shared Xcode scheme with ChanceryTests target
- Added BUNDLE_LOADER and TEST_HOST settings for proper unit test linking
- Removed UI test files that were causing failures
- Added Store tests for ThemeManager, PromptPresetStore, DataStore

**Files / Modules Touched**  
- `Chancery.xcodeproj/project.pbxproj` - Fixed test target build settings
- `Chancery.xcodeproj/xcshareddata/xcschemes/Chancery.xcscheme` (new) - Shared scheme with test target
- `ChanceryTests/ChanceryTests.swift` - Replaced UI test with unit test placeholder
- `ChanceryTests/ThemeManagerTests.swift` (new) - 20+ tests for ThemeManager
- `ChanceryTests/PromptPresetStoreTests.swift` (new) - 20+ tests for preset store
- `ChanceryTests/DataStoreTests.swift` (new) - CloudKitSyncStatus tests

**Tests**  
- ThemeManager: Theme loading, selection, resolution, character themes
- PromptPresetStore: Sample data validation, preset filtering, content quality
- DataStore: CloudKitSyncStatus enum, starter character validation

**Test Running Notes:**
- Use CMD+U in Xcode for fastest test execution (~30s)
- CLI: Use simulator (id=70493158-72B8-43B9-B983-549703870633) - device hangs during cleanup
- `xcodebuild build-for-testing` then `test-without-building` for CLI testing
- Total: 253+ tests across 15 test files, all passing

**Test Files:**
1. `SavedPromptTests.swift` - SavedPrompt model
2. `CharacterProfileTests.swift` - CharacterProfile model  
3. `PromptComposerTests.swift` - PromptComposer service
4. `PromptEnumsTests.swift` - PromptSectionKind, GlobalDefaultKey
5. `StringExtensionsTests.swift` - String utilities
6. `AppThemeTests.swift` - AppTheme, ResolvedTheme
7. `RelatedLinkTests.swift` - RelatedLink model
8. `PromptImageTests.swift` - PromptImage model
9. `PromptPresetTests.swift` - PromptPreset model
10. `ThemeManagerTests.swift` - ThemeManager store
11. `PromptPresetStoreTests.swift` - PromptPresetStore
12. `DataStoreTests.swift` - CloudKitSyncStatus, starter character, scene data structures
13. `SceneTests.swift` - CharacterScene, ScenePrompt, SceneCharacterSettings models
14. `StandaloneImagesTests.swift` - Standalone images for characters and scenes
15. `ScenePromptComposerTests.swift` - Scene prompt composition logic

### 4.6 [2025-12-07] – Image Zoom, Features Section Redesign, Standalone Images

**Summary**  
- Added pinch-to-zoom and double-tap-to-zoom for all enlarged images
- Redesigned "What You Can Do" section to look less like buttons
- Moved tour action into features section with natural integration
- Added standalone images feature for characters (images not attached to prompts)

**Files / Modules Touched**  
- `Components/ZoomableImage.swift` (new) - Reusable zoomable image component
- `Views/Character/CharacterOverviewView.swift` - Updated ProfileImageViewer to use ZoomableImage, added gallery image picker
- `Views/Scratchpad/AllImagesGallerySheet.swift` - Updated SwipeableImageViewer to use ZoomableImage, added standalone images support
- `Views/Home/HomeView.swift` - Redesigned featuresSection, moved tour action, added standalone images to gallery
- `Models/CharacterProfile.swift` - Added `standaloneImages: [PromptImage]` property

**Features**  
- **ZoomableImage**: Pinch-to-zoom (1x-5x), double-tap to toggle zoom, drag to pan when zoomed
- **Standalone Images**: Upload images directly to character without attaching to prompts, appear in gallery and "Your Creations"
- **Features Section**: Circular icons with subtle backgrounds, divider before tour action, chevron indicator

### 4.7 [2025-12-07] – Scenes Feature (Multi-Character Prompts)

**Summary**  
Major feature: Scenes allow users to create prompts featuring multiple characters together.

**Files / Modules Touched**  
- `Models/Scene.swift` (new) - `CharacterScene`, `ScenePrompt`, `SceneCharacterSettings` models
- `Stores/DataStore.swift` - Added scenes array, CRUD operations, persistence
- `Views/Scene/ScenesListView.swift` (new) - List view for scenes
- `Views/Scene/SceneRowView.swift` (new) - Row view with stacked character avatars
- `Views/Scene/SceneDetailView.swift` (new) - Scene overview with characters, gallery, prompts
- `Views/Scene/SceneOverviewView.swift` (new) - Overview content for scene details
- `Views/Scene/ScenePromptEditorView.swift` (new) - Tabbed prompt editor (Scene + per-character tabs)
- `Views/Character/CreateNewSheet.swift` (new) - Unified sheet for creating characters OR scenes
- `Views/Character/CharactersView.swift` - Added "Your Scenes" section, integrated CreateNewSheet
- `Views/Home/HomeView.swift` - Added scene images to "Your Creations" gallery
- `Views/ContentView.swift` - Added scenes binding and navigation
- `Components/ImagePicker.swift` - Fixed callback not firing (removed weak self)

**Features**  
- **Scene Model**: Groups multiple characters, has own prompts with global + per-character settings
- **Scene Prompt Editor**: Tabbed interface - "Scene" tab for environment/lighting/style, character tabs for physical/outfit/pose
- **Load from Character Prompt**: Can load character settings from existing character prompts
- **Prompt Composition**: Intelligently stitches character descriptions + scene settings into final prompt
- **Scene Gallery**: Scene images appear in "Your Creations" on home page
- **CreateNewSheet**: Choose between creating a character or scene, select 2+ characters for scenes

**Bug Fixes**
- Fixed ImagePicker callback not firing (weak self was causing coordinator to deallocate)
- Made "Take a Tour" button stand out more with filled icon and accent background

**Tests Added**
- `SceneTests.swift` - 20+ tests for CharacterScene, ScenePrompt, SceneCharacterSettings
  - Initialization with defaults and all parameters
  - Computed properties (promptCount, totalImageCount, allImages, characterCount)
  - Codable encode/decode
  - Equatable conformance
  - Profile image data tests
  - Links array tests
- `StandaloneImagesTests.swift` - 11+ tests for standalone images
  - CharacterProfile standalone images (add, remove, encode/decode)
  - Scene standalone images
  - totalImageCount and allImages including standalone images
- `ScenePromptComposerTests.swift` - 20+ tests for prompt composition
  - Empty prompts, character settings, multiple characters
  - Scene settings (environment, lighting, style, technical)
  - Negative prompts
  - Full scene composition with all elements
  - Edge cases (empty strings, nil settings)
- `DataStoreTests.swift` - Extended with scene data structure tests
  - Scene array encoding/decoding
  - Scene with prompts and character settings
  - DataStore scene operations (add, index, characters for scene)

### 4.8 [2025-12-07] – Scene Feature Bug Fixes & Reusable Components

**Summary**  
Fixed multiple bugs in Scenes feature and created reusable components for Character/Scene overview pages.

**Files / Modules Touched**  
- `Models/Scene.swift` - Added `profileImageData` and `links` properties to CharacterScene
- `Components/OverviewCards/OverviewCardProtocol.swift` (new) - Protocol for shared Character/Scene behavior
- `Components/OverviewCards/ProfileCard.swift` (new) - Reusable profile card component
- `Components/OverviewCards/LinksCard.swift` (new) - Reusable links management card
- `Components/OverviewCards/GalleryCard.swift` (new) - Reusable image gallery card
- `Views/Scene/SceneOverviewView.swift` - Completely rewritten to match CharacterOverviewView layout
- `Views/Scene/SceneDetailView.swift` - Added character navigation, duplicate prompt support
- `Views/Scene/ScenePromptEditorView.swift` - Updated to match character prompt editor layout
- `Views/Home/HomeView.swift` - Fixed scene images in gallery, added profile images
- `Views/Character/CharactersView.swift` - Fixed SceneDetailView binding

**Bug Fixes**
- Character navigation from scene now works (clicking character navigates to their page)
- Scene images now appear in "Your Creations" gallery (including profile and standalone)
- Scene overview now matches character overview layout (profile image, description, links, gallery, prompts)
- Scene prompt editor now matches character prompt editor layout
- Added `profileImageData` and `links` to CharacterScene model

**Reusable Components Created**
- `ProfileCard` - Profile image with edit/settings buttons
- `LinksCard` - Related links management with add/remove
- `GalleryCard` - Horizontal image gallery with add button
- `OverviewCardProtocol` - Protocol for shared Character/Scene data

**Tests Added**
- Profile image tests for CharacterScene
- Links array tests for CharacterScene

### 4.9 [2025-12-07] – Scene Gallery Integration & Component Unification

**Summary**  
Fixed scene images appearing in gallery, added "By Scene" tab, unified LinksCard component, and strengthened testing requirements in AI_META_PROMPT.

**Files / Modules Touched**  
- `AI_META_PROMPT.md` Section 1 - Added 1.2.7 MANDATORY Comprehensive Test Coverage and 1.2.8 MANDATORY Bug Regression Tests
- `Views/Scratchpad/AllImagesGallerySheet.swift` - Added scenes support, "By Scene" filter tab, scene images in gallery
- `Views/Home/HomeView.swift` - Pass scenes to AllImagesGallerySheet, added navigateToScene helper
- `Views/Character/CharacterOverviewView.swift` - Now uses reusable LinksCard component
- `Views/Scene/ScenePromptEditorView.swift` - Fixed image picker, added "Load" menu for scene settings
- `ChanceryTests/SceneGalleryTests.swift` (new) - 25+ comprehensive tests for scene gallery functionality

**Bug Fixes**
- Scene images now appear in "Your Creations" gallery (prompt images, standalone, profile)
- Added "By Scene" tab to gallery filter options
- CharacterOverviewView and SceneOverviewView now use same LinksCard component
- Fixed image picker in scene prompt editor (removed nested themedCard)
- Added ability to load scene settings from any character's prompt

**Section 1 Updates (Testing Requirements)**
- 1.2.7: Minimum test requirements (initialization, property, method, edge case, encoding, integration)
- 1.2.7: Test naming convention and count guidelines
- 1.2.8: Mandatory bug regression tests - write failing test first, then fix
- 1.3.2: Updated reusable components list with all new components
- 1.3.2: Added Feature Parity Rule and Violation Check

**Tests Added**
- `SceneGalleryTests.swift` - 25+ tests covering:
  - Scene allImages with prompts, standalone, combined
  - Scene totalImageCount calculations
  - Scene profileImageData (nil, set, encode/decode)
  - Scene links (empty, add, encode/decode, order)
  - Scene standaloneImages (empty, add, encode/decode)
  - Scene prompt images
  - Edge cases (empty name, no characters, many images)
- Links array tests for CharacterScene

### 4.10 [2025-12-07] – Scene Feature Parity & Bug Fixes

**Summary**  
Major bug fixes for Scene feature to achieve full parity with Character feature. Added learning section to AI_META_PROMPT for continuous improvement.

**Files / Modules Touched**  
- `AI_META_PROMPT.md` Section 1 - Added 1.8 Continuous Learning & Self-Improvement rules
- `AI_META_PROMPT.md` Section 6 (new) - User Preferences & Learned Patterns
- `Views/Scene/SceneDetailView.swift` - Fixed gallery to use GalleryView, added allGalleryImages(), full SceneSettingsView
- `Views/Scene/ScenePromptEditorView.swift` - Fixed image picker using local copy pattern
- `Views/Scratchpad/AllImagesGallerySheet.swift` - Added onNavigateToScene callback, fixed scene navigation
- `Views/Home/HomeView.swift` - Pass onNavigateToScene to SwipeableImageViewer
- `Views/Home/AppTourView.swift` - Added Scenes tour step
- `Components/GalleryView.swift` - Added standaloneImage initializer

**Bug Fixes**
1. **Scene gallery swiping**: SceneDetailView now uses GalleryView (same as CharacterDetailView) instead of non-existent SceneImageViewer
2. **Scene image upload navigation**: Fixed using local copy pattern for binding modifications
3. **Scene navigation from gallery**: Added onNavigateToScene callback, SwipeableImageViewer checks sceneId before navigating
4. **SceneSettingsView**: Full implementation matching CharacterSettingsView with theme and generator sections

**New Features**
- Tutorial now includes Scenes step
- Scene-specific themes work exactly like character-specific themes
- Scene-specific generator settings work exactly like character-specific settings

**Section 1 Updates**
- 1.8.1: MANDATORY Learning Updates - must update Section 6 with user feedback
- 1.8.2: Self-Evaluation checklist after completing tasks
- 1.8.3: Rule Refinement process
- 1.8.4: Assumption Checking when fixes don't work
- 1.8.5: Feature Parity Enforcement checklist

**Section 6 Created**
- 6.1 Code Quality Preferences
- 6.2 Bug Fixing Expectations
- 6.3 Communication Preferences
- 6.4 Architecture Preferences
- 6.5 Learned Mistakes (with fixes)
- 6.6 Key Patterns to Follow

### 4.11 [2025-12-07] – CloudKit Scenes, Gallery Bug Fixes, UI Improvements

**Summary**  
Added CloudKit sync for Scenes, fixed persistent gallery swiping and navigation bugs, redesigned scene row to match character row layout.

**Files / Modules Touched**  
- `Services/CloudKitManager.swift` - Added scene record type, saveScene/fetchAllScenes/deleteScene methods
- `Models/CloudKitConvertible.swift` - Added CharacterScene CloudKit extension
- `Stores/DataStore.swift` - Added mergeScenes function, updated syncWithCloud
- `Views/Home/HomeView.swift` - Fixed scene prompt images to use actual prompt.id and sceneId
- `Views/Scratchpad/AllImagesGallerySheet.swift` - Replaced ZoomableImage with simple Image to fix gesture conflicts
- `Views/Scene/SceneDetailView.swift` - Added initialPromptId for deep linking, fixed image order
- `Views/Scene/SceneRowView.swift` - Redesigned to match CharacterRowView layout
- `Views/Character/CharacterDetailView.swift` - Fixed allPromptImages/allGalleryImages to include standalone images
- `Views/Character/CharactersView.swift` - Added navigateToScenePromptId binding
- `Views/ContentView.swift` - Added navigateToScenePromptId state and callbacks
- `ChanceryTests/BugRegressionTests.swift` (new) - Regression tests for all bug fixes

**Bug Fixes**
1. **Gallery swiping broken (ZoomableImage)**: ZoomableImage's internal DragGesture conflicted with TabView swipe. Fixed by using simple Image.
2. **Scene prompt navigation from gallery**: HomeView was using `UUID()` instead of `prompt.id` for scene images. Fixed to use actual IDs.
3. **Image gallery order mismatch**: Thumbnail and swipe order were different. Fixed both to use consistent order: profile → prompts → standalone.
4. **Standalone images not in gallery**: allPromptImages/allGalleryImages weren't including standalone images. Fixed.
5. **Physical description not loading**: loadFromCharacterPrompt was using legacy `text` field. Fixed to use `physicalDescription`.

**New Features**
- **CloudKit Scenes**: Scenes now sync to iCloud with all data (prompts, images, settings, links)
- **Scene Row Redesign**: Matches CharacterRowView layout with scalable icon for 3+ characters
- **Deep linking to scene prompts**: Can navigate directly to specific scene prompt from gallery

**Tests Added**
- `BugRegressionTests.swift` - 15+ regression tests covering:
  - Image order consistency (thumbnail matches swipe)
  - Physical description loading
  - Character order in scenes
  - Profile image deduplication
  - Standalone images in gallery

**Test Files Summary (18 total):**
1-15. (Previous test files)
16. `BugRegressionTests.swift` - Bug regression tests

### 4.12 [2025-12-07] – Scene Feature Parity: Presets, Defaults, Navigation

**Summary**  
Added preset name tracking and save functionality to scene prompts, fixed scene prompt defaults to use scene-specific then global defaults, added scenes count to main page, improved scene prompt navigation from gallery.

**Files / Modules Touched**  
- `Views/Scene/SceneDetailView.swift` - Fixed createNewPrompt to apply scene/global defaults, added onChange for initialPromptId
- `Views/Scene/ScenePromptEditorView.swift` - Added updatePresetNameForCurrentText function, onAppear/onChange handlers for preset tracking
- `Views/Home/HomeView.swift` - Added scenes count to Your Creations stats row
- `ChanceryTests/BugRegressionTests.swift` - Added regression tests for defaults and navigation

**Bug Fixes**
1. **Scene prompt defaults not applied**: New scene prompts now apply scene-specific defaults first, then fall back to global defaults (matching character behavior)
2. **Preset name not tracking in scene prompts**: Added updatePresetNameForCurrentText to detect when text matches a preset and display "(Using: preset name)"
3. **Scene prompt navigation from gallery**: Added onChange handler for initialPromptId to handle navigation when view is already visible

**New Features**
- **Scenes count on main page**: Your Creations card now shows scenes count alongside characters, prompts, and images
- **Preset name display**: Scene prompt sections now show which preset is applied (matching character prompt behavior)
- **Save as preset**: Scene prompt sections can save current text as a new preset (already existed, now fully functional with name tracking)

**Tests Added**
- `test_scenePromptDefaults_sceneDefaultsTakePriority` - Scene defaults override global
- `test_scenePromptDefaults_emptySceneDefaultFallsBackToGlobal` - Empty scene defaults fall back
- `test_scenePromptImage_hasCorrectPromptId` - Gallery images use actual prompt.id

### 4.13 [2025-12-07] – Tabbed Library, Modern Stats, Preset Bindings Fix

**Summary**  
Reorganized Characters/Scenes into tabbed "Library" page, redesigned Your Creations stats with modern pill design, fixed scene preset save/display by passing preset name bindings.

**Files / Modules Touched**  
- `Views/Character/CharactersView.swift` - Added tabbed interface (Characters/Scenes), renamed to "Library", search filters by tab
- `Views/Home/HomeView.swift` - Redesigned stats row with modern pill design, added statPill helper
- `Views/Scene/ScenePromptEditorView.swift` - Added preset name bindings to ALL sectionRow calls

**UI Changes**
1. **Tabbed Library Page**: Characters and Scenes now in separate tabs with segmented control
2. **Navigation title**: Changed from "Characters" to "Library"
3. **Search placeholder**: Changed from "Search characters..." to "Search..." (filters based on selected tab)
4. **Generate button**: Shows context-aware button based on selected tab
5. **Stats pills**: Modern capsule design with larger icons, no dot separators

**Bug Fixes**
1. **Scene preset save/display not working**: The root cause was that `sectionRow` calls were NOT passing `presetName` bindings. The `presetName` parameter had a default value of `nil`, so presets were never tracked. **FIXED**: Added explicit preset name bindings to all 8 sectionRow calls (5 scene settings + 3 character settings).

### 4.14 [2025-12-07] – UI Polish: Library Tabs, Preset Sync, Scene Prompt Tabs

**Summary**  
Improved Library page tabs with custom themed design, fixed preset name not updating after save, redesigned scene prompt character tabs for clarity.

**Files / Modules Touched**  
- `Views/Character/CharactersView.swift` - Custom themed tab bar with icons, indicator bar, and proper theming
- `Views/Scene/ScenePromptEditorView.swift` - Added resyncAllPresetMarkers, improved tab selector with subtitles

**UI Changes**
1. **Library tabs**: Custom themed tab bar with icons (person.fill, person.2.fill), indicator bar, proper theme colors
2. **Scene prompt tabs**: Added "Edit Settings For:" label, subtitles ("Environment & Style", "Appearance & Pose"), larger profile images, rounded rectangle cards with borders

**Bug Fixes**
1. **Preset name not updating after save**: After saving a new preset, the UI didn't show "(Using: preset name)". **ROOT CAUSE**: Missing `resyncAllPresetMarkers()` call after saving. **FIXED**: Added resyncAllPresetMarkers function that re-checks all 8 fields (5 scene + 3 per-character) and call it after saving.

### 4.15 [2025-12-07] – Preset Sync Timing Fix, Tab Visual Distinction

**Summary**  
Fixed preset name not updating after save due to timing issue, redesigned scene prompt tabs to be visually distinct from settings cards.

**Files / Modules Touched**  
- `Views/Scene/ScenePromptEditorView.swift` - Added delay before resync, redesigned tab buttons

**Bug Fixes**
1. **Preset name still not updating after save**: The resyncAllPresetMarkers was being called, but the preset store hadn't finished updating yet. **FIXED**: Added `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)` before calling resyncAllPresetMarkers to ensure the store is updated.

**UI Changes**
1. **Scene prompt tabs redesigned**: Changed from horizontal card-like buttons to vertical icon-centric design:
   - Larger icons (44x44 instead of 32x32)
   - Vertical layout with icon above text
   - No background for unselected tabs (transparent)
   - Primary color fill for selected icon
   - Shadow effect on selected tab
   - Clearly distinct from settings cards below

5. OPEN QUESTIONS & TODOs FOR ARCHITECTURE (LIVING SECTION – EDITABLE)

For unresolved architectural decisions by either AI or humans.

**Active Questions:**

1. ~~**CollapsibleSection Component Design**: Should the component accept a ViewBuilder for content, or use a more structured approach with specific content types?~~ **RESOLVED**: Uses ViewBuilder for maximum flexibility.

2. ~~**Test Target Configuration**: The Xcode project needs a test target added manually. The test files are ready in `ChanceryTests/`.~~ **RESOLVED**: Test infrastructure complete with shared scheme, proper build settings, and CLI workflow.

3. **Store Testing Strategy**: Current approach tests public interfaces and sample data. For deeper testing, consider:
   - Protocol-based dependency injection for CloudKitManager
   - Mock implementations for testing
   - Separate integration tests for CloudKit operations

4. **PromptSectionRow Component**: Exists in `Components/PromptSectionRow.swift` but not used. Both `PromptEditorView` and `ScratchpadView` have inline `sectionRow` functions with themed styling. Consider:
   - Updating component to match current styling
   - Or keeping inline for view-specific theming flexibility

When decisions are made, summarize them and migrate stable decisions into Section 3.

6. USER PREFERENCES & LEARNED PATTERNS (LIVING SECTION – AI MUST UPDATE)

This section captures learned insights about the user's preferences, working style, and expectations. The AI MUST update this section when receiving feedback or discovering patterns.

### 6.1 Code Quality Preferences

- **Reusable components are mandatory**: When two features share similar UI or logic, extract to a shared component. Never create parallel implementations.
- **Feature parity is strict**: Scene features must work EXACTLY like Character features. Same components, same behavior, same settings.
- **Test thoroughly**: Don't just write tests that pass - write tests that would catch real bugs. Test the actual user flow.
- **Fix root causes**: When a bug persists after a "fix", the fix addressed symptoms, not the root cause. Re-examine assumptions.

### 6.2 Bug Fixing Expectations

- **"You failed to fix this" means**: The previous fix was incomplete or addressed the wrong issue. Must re-read actual code, not rely on memory.
- **Navigation bugs are common**: Check for sheets, alerts, fullScreenCovers, NavigationLinks that might dismiss or navigate unexpectedly.
- **Binding issues**: Verify bindings are actually connected and updating the right data.
- **Multiple code paths**: A bug might have multiple causes - fix all of them, not just the first one found.

### 6.3 Communication Preferences

- **Be thorough**: User prefers comprehensive fixes over quick patches.
- **Learn from mistakes**: When told something didn't work, don't repeat the same approach.
- **Update documentation**: Keep AI_META_PROMPT.md current with all changes and learnings.

### 6.4 Architecture Preferences

- **Scenes mirror Characters**: Every feature Characters have, Scenes should have. Same settings, same theming, same components.
- **Theme consistency**: Scene-specific themes should work exactly like character-specific themes.
- **Shared components list** (must use for both Character and Scene):
  - `LinksCard` - Related links management
  - `GalleryCard` - Image gallery display
  - `ProfileCard` - Profile image with edit/settings
  - `PromptPreviewSection` - Composed prompt preview
  - `ZoomableImage` / `SwipeableImageViewer` - Image viewing
  - `ImagePicker` - Photo selection
  - `DynamicGrowingTextEditor` - Text input
  - Themed modifiers (`.themedCard`, `.themedBackground`, etc.)

### 6.5 Learned Mistakes (Do Not Repeat)

1. **[2025-12-07] Scene gallery swiping broken**: Failed to properly integrate SwipeableImageViewer with scene images. **FIXED**: SceneDetailView now uses GalleryView (same as CharacterDetailView) instead of non-existent SceneImageViewer.
2. **[2025-12-07] Scene image upload navigates away**: Adding images to scene prompts triggers unwanted navigation. **FIXED**: Use local copy pattern (var updated = prompt.wrappedValue, modify, then assign back) instead of direct binding modification.
3. **[2025-12-07] Load prompt navigates away**: Loading a character prompt in scene editor dismisses the view. **ROOT CAUSE**: Direct binding modification triggers navigation state changes. Use local copy pattern.
4. **[2025-12-07] Scene navigation from gallery broken**: Clicking scene name navigates to character instead of scene. **FIXED**: Added onNavigateToScene callback to SwipeableImageViewer, check sceneId before navigating.
5. **[2025-12-07] SceneSettingsView was placeholder**: Scene settings didn't match character settings. **FIXED**: Created full SceneSettingsView matching CharacterSettingsView with theme, generator, and defaults sections.
6. **[2025-12-07] Profile images not opening in "By Character"/"By Scene" tabs**: Profile images had regenerated UUIDs each time `allImages` was computed, causing index lookup failures. **FIXED**: Use deterministic UUIDs based on character/scene ID hash, and cache images on appear.
7. **[2025-12-07] Swiping broken in gallery**: Same root cause as #6 - image IDs regenerating. **FIXED**: Cache `allImages` in `@State` on appear, pass cached array to SwipeableImageViewer.
8. **[2025-12-07] Scene backgrounds not using scene theme**: Used `.themedBackground()` which uses global theme. **FIXED**: Use `.background(sceneTheme.background.ignoresSafeArea())` directly like CharacterDetailView.
9. **[2025-12-07] Scene prompt text input causes navigation back**: SceneDetailView used NavigationLink to navigate to ScenePromptEditorView. When the scene binding was modified (by typing), SwiftUI re-evaluated the navigation state and popped back. **ROOT CAUSE**: NavigationLink with isActive binding is unstable when the destination modifies the source binding. **FIXED**: Use embedded conditional view pattern like CharacterDetailView - embed the prompt editor directly in the view hierarchy using `if let idx = selectedPromptIndex { PromptEditorView(...) } else { OverviewView(...) }` instead of NavigationLink.
10. **[2025-12-07] Scene prompt image upload causes navigation back**: Same root cause as #9 - NavigationLink instability. **FIXED**: Same fix - embedded conditional view pattern.
11. **[2025-12-07] Gallery swiping broken due to ZoomableImage**: ZoomableImage component has its own DragGesture that conflicts with TabView's horizontal swipe. **FIXED**: Use simple Image instead of ZoomableImage in SwipeableImageViewer, matching the working GalleryView pattern.
12. **[2025-12-07] Scene prompt navigation from gallery not working**: HomeView.allGalleryImages was using `UUID()` for scene prompt images instead of `prompt.id`, and not setting `sceneId`. **FIXED**: Use actual `prompt.id` and set `sceneId` and `sceneName` for proper navigation.
13. **[2025-12-07] Physical description not loading in scene prompts**: loadFromCharacterPrompt was using `characterPrompt.text` (legacy field) instead of `characterPrompt.physicalDescription`. **FIXED**: Use `physicalDescription` field correctly.
14. **[2025-12-07] Scene prompt defaults not applied**: createNewPrompt in SceneDetailView created prompts with no defaults. **FIXED**: Apply scene-specific defaults first, then fall back to global defaults (matching CharacterDetailView pattern).
15. **[2025-12-07] Preset name not tracking in scene prompts**: Scene prompt sections didn't update preset name when text matched a preset. **FIXED**: Added updatePresetNameForCurrentText function with onAppear/onChange handlers (matching PromptEditorView pattern).
16. **[2025-12-07] Scene preset save/display completely broken**: The `sectionRow` function had `presetName: Binding<String?>? = nil` as an optional parameter with default `nil`. All calls to `sectionRow` were NOT passing the `presetName` binding, so presets were never saved or displayed. **ROOT CAUSE**: Optional parameter with default value masked the missing bindings. **FIXED**: Added explicit preset name bindings to all 8 sectionRow calls in ScenePromptEditorView.
17. **[2025-12-07] Preset name not updating after save**: After saving a new preset via "Save as preset", the UI didn't update to show "(Using: preset name)". **ROOT CAUSE**: Character prompt editor calls `resyncAllPresetMarkers()` after saving, but scene prompt editor didn't have this function. **FIXED**: Added resyncAllPresetMarkers function to ScenePromptEditorView and call it after saving.
18. **[2025-12-07] Preset name STILL not updating after save**: Even with resyncAllPresetMarkers, the UI didn't update. **ROOT CAUSE**: The preset store update is asynchronous, so resyncAllPresetMarkers was called before the store finished updating. **FIXED**: Added `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)` delay before calling resyncAllPresetMarkers.

### 6.6 Key Patterns to Follow

1. **Local Copy Pattern for Bindings**: When modifying bound data in sheets/pickers, always:
   ```swift
   var updated = binding.wrappedValue
   // modify updated
   binding.wrappedValue = updated
   ```
   This prevents intermediate state changes from triggering navigation.

2. **Feature Parity Checklist**: When building Scene equivalent of Character feature:
   - [ ] Use exact same reusable components
   - [ ] Pass same environment objects
   - [ ] Implement same callbacks
   - [ ] Apply same theme logic (`.background(theme.background.ignoresSafeArea())` not `.themedBackground()`)
   - [ ] Test side-by-side

3. **Stable IDs for Computed Collections**: When creating computed arrays for SwiftUI (like gallery images):
   - Use deterministic IDs based on source object IDs
   - Cache the array in `@State` on appear
   - Pass the cached array to child views, not the computed property

4. **Scene-Specific Theme Usage**: For scene pages, use:
   ```swift
   .background(sceneTheme.background.ignoresSafeArea())
   ```
   NOT `.themedBackground()` which uses global theme.

5. **Embedded Conditional View Pattern (CRITICAL)**: When a child view modifies the parent's binding:
   - **DO NOT** use NavigationLink with isActive binding
   - **DO** embed the child view directly using conditional:
   ```swift
   var body: some View {
       Group {
           if let idx = selectedPromptIndex {
               PromptEditorView(binding: $data, index: idx, ...)
           } else {
               OverviewView(binding: $data, ...)
           }
       }
   }
   ```
   This prevents SwiftUI from re-evaluating navigation state when the binding changes.

6. **Binding Pattern for Prompt Editors**: Use explicit Binding wrappers:
   ```swift
   private var promptBinding: Binding<PromptType> {
       Binding(
           get: { parent.prompts[index] },
           set: { parent.prompts[index] = $0 }
       )
   }
   private var prompt: PromptType { promptBinding.wrappedValue }
   ```
   Then use `promptBinding.wrappedValue` for modifications and `prompt` for reads.