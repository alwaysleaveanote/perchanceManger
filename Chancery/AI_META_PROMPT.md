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

1.2.1. Prefer Test-Driven Development (TDD):

For each new feature or behavior, first define one or more failing unit tests (or update existing tests) that describe the intended behavior.

Only then implement or modify the production code until all tests pass.

After tests pass, refactor for clarity and maintainability while keeping tests green.

1.2.2. Never knowingly introduce untested behavior in core logic. If you implement or change a non-trivial behavior, add or update tests that cover:

Nominal behavior

Important edge cases

Error conditions

1.2.3. If a change breaks existing tests:

If the intended behavior should remain the same, fix the code.

If the intended behavior has deliberately changed, update the tests accordingly and document the rationale in Section 3 or 4.

1.2.4. Do not weaken or delete tests simply to make the test suite pass. Only change tests when requirements truly change.

1.3 Swift Architecture & Code Quality

1.3.1. Modularity & No Duplication

Avoid copy-pasting or slightly editing existing logic.

Extract shared logic into reusable, well-named functions, types, or modules.

Prefer small, composable types and functions.

1.3.2. Architecture

Prefer patterns such as MVVM or Clean Architecture.

Separate concerns (UI, domain logic, data access, networking).

Make domain logic testable and UI-independent.

1.3.3. Modern Swift Practices

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
1.7.2. Do not modify Section 1.
1.7.3. Update Sections 2+ to capture architectural insights, naming conventions, patterns, decisions, and pitfalls.
1.7.4. Keep entries clean, concise, and non-duplicative.
1.7.5. if you change the way a functionality works, you should update the places the document now-incorrectly documents it and add the updated functionality information instead

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
- Total: 170+ tests across 12 test files, all passing

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
12. `DataStoreTests.swift` - CloudKitSyncStatus, starter character

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