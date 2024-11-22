//
//  ImageNavigation.swift
//  DailyPic
//
//  Created by Paul Zenker on 23.11.24.
//

import SwiftUI

public struct ImageNavigation: View {
    @ObservedObject var imageManager: ImageManager
    
    
    public var body: some View {
        HStack(spacing: 3) {
            // Backward Button
            Button(action: {
                imageManager.showPreviousImage()
            }) {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .opacity(imageManager.isFirstImage() ? 0.2 : 1)
            }
            .scaledToFill()
            .layoutPriority(1)
            .buttonStyle(.borderless)
            .hoverEffect()
            .disabled(imageManager.isFirstImage())
            
            // Favorite Button
            Button(action: {imageManager.makeFavorite( bool: !imageManager.isCurrentFavorite() )}) {
                Image(systemName: imageManager.isCurrentFavorite() ? "star.fill" : "star")
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .font(.title2)
            }
            .scaledToFill()
            .buttonStyle(.borderless)
            .layoutPriority(1)
            .hoverEffect()

            // Shuffle Button
            Button(action: { imageManager.shuffleIndex() } ) {
                Image(systemName: "dice")
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .font(.title2)
            }
            .scaledToFill()
            .buttonStyle(.borderless)
            .layoutPriority(1)
            .hoverEffect()
            
            
            // Forward Button
            Button(action: {
                imageManager.showNextImage()
            }) {
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .opacity(imageManager.isLastImage() ? 0.2 : 1)
            }
            .scaledToFill()
            .layoutPriority(1)
            .buttonStyle(.borderless)
            .hoverEffect()
            .disabled(imageManager.isLastImage())
        }
        .padding(.vertical, 1)
        .padding(.horizontal, 6)
    }
}
