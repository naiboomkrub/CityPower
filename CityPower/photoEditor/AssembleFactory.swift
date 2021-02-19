//
//  AssembleFactory.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import UIKit

public final class AssemblyFactory: CameraAssemblyFactory, MediaPickerAssemblyFactory,
    PhotoLibraryAssemblyFactory, ImageCroppingAssemblyFactory {
    
    private let serviceFactory: ServiceFactory
    
    public init(imageStorage: ImageStorage = ImageStorageImpl()) {
        self.serviceFactory = ServiceFactoryImpl(imageStorage: imageStorage)
    }
    
    func cameraAssembly() -> CameraAssembly {
        return CameraAssemblyImpl(serviceFactory: serviceFactory)
    }
    
    public func mediaPickerAssembly() -> MediaPickerAssembly {
        return MediaPickerAssemblyImpl(assemblyFactory: self, serviceFactory: serviceFactory)
    }

    func imageCroppingAssembly() -> ImageCroppingAssembly {
        return ImageCroppingAssemblyImpl(serviceFactory: serviceFactory)
    }

    public func photoLibraryAssembly() -> PhotoLibraryAssembly {
        return PhotoLibraryAssemblyImpl(serviceFactory: serviceFactory)
    }
}


public protocol PaparazzoPickerModule: class {
    
    func focusOnModule()
    func dismissModule()
    
    func finish()
    
    func setContinueButtonEnabled(_: Bool)
    func setContinueButtonVisible(_: Bool)
    
    func setCameraTitle(_: String)
    func setCameraSubtitle(_: String)
    func setCameraHint(data: CameraHintData)
    
    func setThumbnailsAlwaysVisible(_: Bool)
    
    func removeItem(_: MediaPickerItem)
 
    var onItemsAdd: (([MediaPickerItem], _ startIndex: Int) -> ())? { get set }
    var onItemUpdate: ((MediaPickerItem, _ index: Int?) -> ())? { get set }
    var onItemMove: ((_ sourceIndex: Int, _ destinationIndex: Int) -> ())? { get set }
    var onItemRemove: ((MediaPickerItem, _ index: Int?) -> ())? { get set }
    var onCropFinish: (() -> ())? { get set }
    var onCropCancel: (() -> ())? { get set }
    var onContinueButtonTap: (() -> ())? { get set }
    
    var onViewDidLoad: (() -> ())? { get set }
    var onFinish: (([MediaPickerItem]) -> ())? { get set }
    var onCancel: (() -> ())? { get set }
}



