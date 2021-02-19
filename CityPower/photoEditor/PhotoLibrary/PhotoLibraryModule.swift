//
//  PhotoLibraryModule.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit

public struct PhotoLibraryData {
    public let selectedItems: [PhotoLibraryItem]
    public let maxSelectedItemsCount: Int?
    
    public init(
        selectedItems: [PhotoLibraryItem] = [],
        maxSelectedItemsCount: Int? = nil)
    {
        self.selectedItems = selectedItems
        self.maxSelectedItemsCount = maxSelectedItemsCount
    }
}

public protocol PhotoLibraryModule: class {
    
    func dismissModule()
    
    var onFinish: ((PhotoLibraryModuleResult) -> ())? { get set }
}

public enum PhotoLibraryModuleResult {
    case selectedItems([PhotoLibraryItem])
    case cancelled
}


protocol PhotoLibraryInteractor: class {
    
    var currentAlbum: PhotoLibraryAlbum? { get }
    var selectedItems: [PhotoLibraryItem] { get }
    
    func observeAuthorizationStatus(handler: @escaping (_ accessGranted: Bool) -> ())
    func observeAlbums(handler: @escaping ([PhotoLibraryAlbum]) -> ())
    func observeCurrentAlbumEvents(handler: @escaping (PhotoLibraryAlbumEvent, PhotoLibraryItemSelectionState) -> ())
    
    func isSelected(_: PhotoLibraryItem) -> Bool
    func selectItem(_: PhotoLibraryItem) -> PhotoLibraryItemSelectionState
    func deselectItem(_: PhotoLibraryItem) -> PhotoLibraryItemSelectionState
    func prepareSelection() -> PhotoLibraryItemSelectionState
    
    func setCurrentAlbum(_: PhotoLibraryAlbum)
}

public struct PhotoLibraryItem: Equatable {
    
    public var image: ImageSource
    
    init(image: ImageSource) {
        self.image = image
    }
    
    public static func ==(item1: PhotoLibraryItem, item2: PhotoLibraryItem) -> Bool {
        return item1.image == item2.image
    }
}

struct PhotoLibraryItemSelectionState {
    
    enum PreSelectionAction {
        case none
        case deselectAll
    }
    
    var isAnyItemSelected: Bool
    var canSelectMoreItems: Bool
    var preSelectionAction: PreSelectionAction
}

enum PhotoLibraryAlbumEvent {
    case fullReload([PhotoLibraryItem])
    case incrementalChanges(PhotoLibraryChanges)
}

struct PhotoLibraryChanges {

    let removedIndexes: IndexSet
    let insertedItems: [(index: Int, item: PhotoLibraryItem)]
    let updatedItems: [(index: Int, item: PhotoLibraryItem)]
    let movedIndexes: [(from: Int, to: Int)]
    
    let itemsAfterChanges: [PhotoLibraryItem]
}


final class PhotoLibraryInteractorImpl: PhotoLibraryInteractor {
    
    private var maxSelectedItemsCount: Int?
    private var onAlbumEvent: ((PhotoLibraryAlbumEvent, PhotoLibraryItemSelectionState) -> ())?
    
    private let photoLibraryItemsService: PhotoLibraryItemsService
        
    init(selectedItems: [PhotoLibraryItem], maxSelectedItemsCount: Int? = nil, photoLibraryItemsService: PhotoLibraryItemsService) {
        self.selectedItems = selectedItems
        self.maxSelectedItemsCount = maxSelectedItemsCount
        self.photoLibraryItemsService = photoLibraryItemsService
    }
    
    private(set) var currentAlbum: PhotoLibraryAlbum?
    private(set) var selectedItems = [PhotoLibraryItem]()
    
    func observeAuthorizationStatus(handler: @escaping (_ accessGranted: Bool) -> ()) {
        photoLibraryItemsService.observeAuthorizationStatus(handler: handler)
    }
    
    func observeAlbums(handler: @escaping ([PhotoLibraryAlbum]) -> ()) {
        photoLibraryItemsService.observeAlbums { [weak self] albums in
            if let currentAlbum = self?.currentAlbum {
                // Reset current album if it has been removed, otherwise refresh it (title might have been changed).
                self?.currentAlbum = albums.first { $0 == currentAlbum }
            }
            handler(albums)
        }
    }
    
    func observeCurrentAlbumEvents(handler: @escaping (PhotoLibraryAlbumEvent, PhotoLibraryItemSelectionState) -> ()) {
        onAlbumEvent = handler
    }
    
    func isSelected(_ item: PhotoLibraryItem) -> Bool {
        return selectedItems.contains(item)
    }
    
    func selectItem(_ item: PhotoLibraryItem) -> PhotoLibraryItemSelectionState {
        if canSelectMoreItems() {
            selectedItems.append(item)
        }
        return selectionState()
    }
    
    func deselectItem(_ item: PhotoLibraryItem) -> PhotoLibraryItemSelectionState {
        if let index = selectedItems.firstIndex(of: item) {
            selectedItems.remove(at: index)
        }
        return selectionState()
    }
    
    func prepareSelection() -> PhotoLibraryItemSelectionState {
        if selectedItems.count > 0 && maxSelectedItemsCount == 1 {
            selectedItems.removeAll()
            return selectionState(preSelectionAction: .deselectAll)
        } else {
            return selectionState()
        }
    }
    
    func setCurrentAlbum(_ album: PhotoLibraryAlbum) {
        guard album != currentAlbum else { return }
        
        currentAlbum = album
        
        photoLibraryItemsService.observeEvents(in: album) { [weak self] event in
            guard let strongSelf = self else { return }

            if let onAlbumEvent = strongSelf.onAlbumEvent {
                dispatch_to_main_queue {
                    onAlbumEvent(event, strongSelf.selectionState())
                }
            }
        }
    }
    
    private func canSelectMoreItems() -> Bool {
        return maxSelectedItemsCount.flatMap { selectedItems.count < $0 } ?? true
    }
    
    private func selectionState(preSelectionAction: PhotoLibraryItemSelectionState.PreSelectionAction = .none) -> PhotoLibraryItemSelectionState {
        return PhotoLibraryItemSelectionState(
            isAnyItemSelected: selectedItems.count > 0,
            canSelectMoreItems: canSelectMoreItems(),
            preSelectionAction: preSelectionAction
        )
    }
}
