//
//  ImagePicker.swift
//  PerchanceImageGenerator
//
//  A SwiftUI wrapper for PHPickerViewController, enabling photo library access.
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - ImagePicker

/// A SwiftUI wrapper for `PHPickerViewController` that supports multiple image selection.
///
/// This picker uses the modern PHPicker API which doesn't require photo library
/// permissions for basic selection operations.
///
/// ## Usage
/// ```swift
/// .sheet(isPresented: $showingPicker) {
///     ImagePicker { images in
///         // Handle selected images
///         for image in images {
///             saveImage(image)
///         }
///     }
/// }
/// ```
struct ImagePicker: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    /// Callback invoked when the user finishes selecting images
    var onImagesPicked: ([UIImage]) -> Void
    
    /// Maximum number of images that can be selected (0 = unlimited)
    var selectionLimit: Int = 0
    
    // MARK: - UIViewControllerRepresentable
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagesPicked: onImagesPicked)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        Logger.debug("Presenting image picker (limit: \(selectionLimit == 0 ? "unlimited" : "\(selectionLimit)"))", category: .ui)
        
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = selectionLimit
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // PHPicker doesn't support configuration updates after creation
    }
}

// MARK: - Coordinator

extension ImagePicker {
    
    /// Coordinator that handles PHPickerViewController delegate callbacks
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        
        // MARK: - Properties
        
        private let onImagesPicked: ([UIImage]) -> Void
        
        // MARK: - Initialization
        
        init(onImagesPicked: @escaping ([UIImage]) -> Void) {
            self.onImagesPicked = onImagesPicked
        }
        
        // MARK: - PHPickerViewControllerDelegate
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard !results.isEmpty else {
                Logger.debug("Image picker dismissed without selection", category: .ui)
                return
            }
            
            Logger.debug("Processing \(results.count) selected images", category: .ui)
            
            var loadedImages: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
                
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        Logger.error("Failed to load image: \(error.localizedDescription)", category: .ui)
                        return
                    }
                    
                    if let image = object as? UIImage {
                        loadedImages.append(image)
                    }
                }
            }
            
            group.notify(queue: .main) { [weak self] in
                guard !loadedImages.isEmpty else { return }
                Logger.info("Successfully loaded \(loadedImages.count) images", category: .ui)
                self?.onImagesPicked(loadedImages)
            }
        }
    }
}
