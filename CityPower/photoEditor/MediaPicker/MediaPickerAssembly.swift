//
//  MediaPickerAssembly.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import UIKit


public protocol MediaPickerAssembly: class {
    func module(data: MediaPickerData, isNewFlowPrototype: Bool, configure: (MediaPickerModule) -> ()) -> UIViewController
}

public extension MediaPickerAssembly {
    func module(data: MediaPickerData, configure: (MediaPickerModule) -> ()) -> UIViewController {
        return module(data: data, isNewFlowPrototype: false, configure: configure)
    }
}

public protocol MediaPickerAssemblyFactory: class {
    func mediaPickerAssembly() -> MediaPickerAssembly
}


public final class MediaPickerAssemblyImpl: BasePhotoEditorAssembly, MediaPickerAssembly {
    
    typealias AssemblyFactory = CameraAssemblyFactory & ImageCroppingAssemblyFactory & PhotoLibraryAssemblyFactory
    
    private let assemblyFactory: AssemblyFactory
    
    init(assemblyFactory: AssemblyFactory, serviceFactory: ServiceFactory) {
        self.assemblyFactory = assemblyFactory
        super.init(serviceFactory: serviceFactory)
    }

    public func module(data: MediaPickerData, isNewFlowPrototype: Bool,
        configure: (MediaPickerModule) -> ()) -> UIViewController {
        let interactor = MediaPickerInteractorImpl(
            items: data.items,
            selectedItem: data.selectedItem,
            maxItemsCount: data.maxItemsCount,
            cropCanvasSize: data.cropCanvasSize,
            cameraEnabled: data.cameraEnabled,
            latestLibraryPhotoProvider: serviceFactory.photoLibraryLatestPhotoProvider()
        )
        
        let viewController = MediaPickerViewController()

        let router = MediaPickerUIKitRouter(assemblyFactory: assemblyFactory, viewController: viewController)
        
        let cameraAssembly = assemblyFactory.cameraAssembly()
        let (cameraView, cameraModuleInput) = cameraAssembly.module(initialActiveCameraType: .back)
        
        let presenter = MediaPickerPresenter(isNewFlowPrototype: isNewFlowPrototype, interactor: interactor, router: router, cameraModuleInput: cameraModuleInput)
        
        viewController.addDisposable(presenter)
        viewController.setCameraView(cameraView)
        viewController.setShowsCropButton(data.cropEnabled)
        viewController.setHapticFeedbackEnabled(data.hapticFeedbackEnabled)
        
        presenter.view = viewController
        
        configure(presenter)
        
        return viewController
    }
}


public struct CameraHintData {
    public let title: String
    public let delay: TimeInterval?
    
    public init(
        title: String,
        delay: TimeInterval? = nil)
    {
        self.title = title
        self.delay = delay
    }
}


protocol MediaPickerInteractor: class {
    
    var items: [MediaPickerItem] { get }
    var cropCanvasSize: CGSize { get }
    var cameraEnabled: Bool { get }
    var photoLibraryItems: [PhotoLibraryItem] { get }
    var selectedItem: MediaPickerItem? { get }
    var maxItemsCount: Int? { get }
    
    func addItems(_ items: [MediaPickerItem]) -> (addedItems: [MediaPickerItem], startIndex: Int)
    func addPhotoLibraryItems(_ photoLibraryItems: [PhotoLibraryItem]) -> (addedItems: [MediaPickerItem], startIndex: Int)
    
    func updateItem(_ item: MediaPickerItem)
    func removeItem(_ item: MediaPickerItem) -> MediaPickerItem?
    func selectItem(_: MediaPickerItem?)
    func moveItem(from sourceIndex: Int, to destinationIndex: Int)
    func indexOfItem(_ item: MediaPickerItem) -> Int?
    func numberOfItemsAvailableForAdding() -> Int?
    
    func observeLatestPhotoLibraryItem(handler: @escaping (ImageSource?) -> ())
    func canAddItems() -> Bool
    
}


final class MediaPickerInteractorImpl: MediaPickerInteractor {
    
    private let latestLibraryPhotoProvider: PhotoLibraryLatestPhotoProvider
    
    let maxItemsCount: Int?
    let cropCanvasSize: CGSize
    
    private(set) var items = [MediaPickerItem]()
    private(set) var photoLibraryItems = [PhotoLibraryItem]()
    private(set) var selectedItem: MediaPickerItem?
    let cameraEnabled: Bool
    
    init(
        items: [MediaPickerItem],
        selectedItem: MediaPickerItem?,
        maxItemsCount: Int?,
        cropCanvasSize: CGSize,
        cameraEnabled: Bool,
        latestLibraryPhotoProvider: PhotoLibraryLatestPhotoProvider
    ) {
        self.items = items
        self.selectedItem = selectedItem
        self.maxItemsCount = maxItemsCount
        self.cropCanvasSize = cropCanvasSize
        self.cameraEnabled = cameraEnabled
        self.latestLibraryPhotoProvider = latestLibraryPhotoProvider
    }
    
    func observeLatestPhotoLibraryItem(handler: @escaping (ImageSource?) -> ()) {
        latestLibraryPhotoProvider.observePhoto(handler: handler)
    }
    
    func addItems(_ items: [MediaPickerItem]) -> (addedItems: [MediaPickerItem], startIndex: Int) {
        
        let items = items.filter { !self.items.contains($0) }
        
        let numberOfItemsToAdd = min(items.count, maxItemsCount.flatMap { $0 - self.items.count } ?? Int.max)
        let itemsToAdd = items[0..<numberOfItemsToAdd]
        let startIndex = self.items.count
        self.items.append(contentsOf: itemsToAdd)
        
        return (Array(itemsToAdd), startIndex)
    }
    
    func addPhotoLibraryItems(_ photoLibraryItems: [PhotoLibraryItem]) -> (addedItems: [MediaPickerItem], startIndex: Int) {
        let mediaPickerItems = photoLibraryItems.map {
            MediaPickerItem(image: $0.image, source: .photoLibrary) }
        
        self.photoLibraryItems.append(contentsOf: photoLibraryItems)
        
        return addItems(mediaPickerItems)
    }
    
    func updateItem(_ item: MediaPickerItem) {
        
        if let index = items.firstIndex(of: item) {
            items[index] = item
        }
        
        if let selectedItem = selectedItem, item == selectedItem {
            self.selectedItem = item
        }
    }
    
    func removeItem(_ item: MediaPickerItem) -> MediaPickerItem? {
        
        var adjacentItem: MediaPickerItem?
        
        if let index = items.firstIndex(of: item) {
        
            items.remove(at: index)
        
            if index < items.count {
                adjacentItem = items[index]
            } else if index > 0 {
                adjacentItem = items[index - 1]
            }
        }
        
        if let matchingPhotoLibraryItemIndex = photoLibraryItems.firstIndex(where: { $0.image == item.image }) {
            photoLibraryItems.remove(at: matchingPhotoLibraryItemIndex)
        }
        
        return adjacentItem
    }
    
    func selectItem(_ item: MediaPickerItem?) {
        selectedItem = item
    }
    
    func moveItem(from sourceIndex: Int, to destinationIndex: Int) {
        items.moveElement(from: sourceIndex, to: destinationIndex)
    }
    
    func indexOfItem(_ item: MediaPickerItem) -> Int? {
        return items.firstIndex(of: item)
    }
    
    func numberOfItemsAvailableForAdding() -> Int? {
        return maxItemsCount.flatMap { $0 - items.count }
    }
    
    func canAddItems() -> Bool {
        return maxItemsCount.flatMap { self.items.count < $0 } ?? true
    }
}
