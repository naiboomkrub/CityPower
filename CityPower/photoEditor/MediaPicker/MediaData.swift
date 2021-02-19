//
//  MediaData.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit


public protocol MediaPickerModule: PaparazzoPickerModule {  }

public struct MediaPickerData {
    public let items: [MediaPickerItem]
    public let selectedItem: MediaPickerItem?
    public let maxItemsCount: Int?
    public let cropEnabled: Bool
    public let hapticFeedbackEnabled: Bool
    public let cropCanvasSize: CGSize
    public let cameraEnabled: Bool
    
    public init(
        items: [MediaPickerItem] = [],
        selectedItem: MediaPickerItem? = nil,
        maxItemsCount: Int? = nil,
        cropEnabled: Bool = true,
        hapticFeedbackEnabled: Bool = false,
        cropCanvasSize: CGSize = CGSize(width: 1280, height: 960),
        cameraEnabled: Bool = true)
    {
        self.items = items
        self.selectedItem = selectedItem
        self.maxItemsCount = maxItemsCount
        self.cropEnabled = cropEnabled
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.cropCanvasSize = cropCanvasSize
        self.cameraEnabled = cameraEnabled
    }
}


public final class MediaPickerItem: Equatable {
    
    public enum Source {
        case camera
        case photoLibrary
    }
    
    public let image: ImageSource
    public let source: Source
    
    let originalItem: MediaPickerItem?
    
    public init(
        image: ImageSource,
        source: Source,
        originalItem: MediaPickerItem? = nil)
    {
        self.image = image
        self.source = source
        self.originalItem = originalItem
    }
    
    public convenience init(_ photoLibraryItem: PhotoLibraryItem) {
        self.init(image: photoLibraryItem.image, source: .photoLibrary, originalItem: nil)
    }
    
    public static func ==(item1: MediaPickerItem, item2: MediaPickerItem) -> Bool {
        return item1.image == item2.image
            || item1.originalItem?.image == item2.image
            || item2.originalItem?.image == item1.image
    }
}

