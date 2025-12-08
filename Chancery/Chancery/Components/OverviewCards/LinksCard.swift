//
//  LinksCard.swift
//  Chancery
//
//  Reusable links card component for Character and Scene overview pages.
//

import SwiftUI

/// A reusable card for displaying and managing related links.
/// Used by both CharacterOverviewView and SceneOverviewView.
struct LinksCard: View {
    @Binding var links: [RelatedLink]
    let themeId: String?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showAddLinkForm = false
    @State private var newLinkTitle = ""
    @State private var newLinkURL = ""
    
    private var theme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: themeId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Related Links")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showAddLinkForm.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showAddLinkForm ? "xmark" : "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text(showAddLinkForm ? "Cancel" : "Add")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(showAddLinkForm ? theme.textSecondary : theme.textOnPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(showAddLinkForm ? theme.backgroundTertiary : theme.primary)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Add link form
            if showAddLinkForm {
                addLinkForm
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            }
            
            // Links list
            if links.isEmpty && !showAddLinkForm {
                Text("Tap + to add reference links")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            } else if !links.isEmpty {
                linksListView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard(characterThemeId: themeId)
    }
    
    // MARK: - Add Link Form
    
    private var addLinkForm: some View {
        VStack(spacing: 12) {
            TextField("Link Title (optional)", text: $newLinkTitle)
                .textFieldStyle(.roundedBorder)
            
            TextField("URL", text: $newLinkURL)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .autocapitalization(.none)
            
            Button {
                addLink()
            } label: {
                Text("Add Link")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.textOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                            .fill(theme.primary)
                    )
            }
            .buttonStyle(.plain)
            .disabled(newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .fill(theme.backgroundTertiary)
        )
    }
    
    // MARK: - Links List
    
    @ViewBuilder
    private var linksListView: some View {
        if links.count > 4 {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(links) { link in
                        linkRow(link: link)
                    }
                }
            }
            .frame(maxHeight: 280)
        } else {
            VStack(spacing: 8) {
                ForEach(links) { link in
                    linkRow(link: link)
                }
            }
        }
    }
    
    // MARK: - Link Row
    
    private func linkRow(link: RelatedLink) -> some View {
        HStack(spacing: 12) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: link.isValid ? "link" : "exclamationmark.triangle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(link.isValid ? theme.primary : theme.warning)
            }
            
            // Link info
            VStack(alignment: .leading, spacing: 2) {
                Text(link.title.isEmpty ? "Untitled Link" : link.title)
                    .font(.subheadline.weight(.medium))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
                
                if let host = link.host {
                    Text(host)
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                } else {
                    Text(link.urlString)
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 4) {
                // Open link button
                if let url = link.url {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 16))
                            .foregroundColor(theme.primary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                
                // Delete button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        removeLink(link)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(theme.error.opacity(0.8))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .fill(theme.backgroundTertiary)
        )
    }
    
    // MARK: - Actions
    
    private func addLink() {
        let trimmedURL = newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else { return }
        
        let trimmedTitle = newLinkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let link = RelatedLink(
            title: trimmedTitle,
            urlString: trimmedURL
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            links.append(link)
            newLinkTitle = ""
            newLinkURL = ""
            showAddLinkForm = false
        }
    }
    
    private func removeLink(_ link: RelatedLink) {
        if let index = links.firstIndex(where: { $0.id == link.id }) {
            links.remove(at: index)
        }
    }
}
