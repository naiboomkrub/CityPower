//
//  PhotoLibraryAssemble.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit

public protocol PhotoLibraryAssembly: class {
    func module(data: PhotoLibraryData, configure: (PhotoLibraryModule) -> ()) -> UIViewController
}

public protocol PhotoLibraryAssemblyFactory: class {
    func photoLibraryAssembly() -> PhotoLibraryAssembly
}


public final class PhotoLibraryAssemblyImpl: BasePhotoEditorAssembly, PhotoLibraryAssembly {
    
    public func module(data: PhotoLibraryData, configure: (PhotoLibraryModule) -> ()) -> UIViewController {
        
        let photoLibraryItemsService = PhotoLibraryItemsServiceImpl()
        
        let interactor = PhotoLibraryInteractorImpl(
            selectedItems: data.selectedItems,
            maxSelectedItemsCount: data.maxSelectedItemsCount,
            photoLibraryItemsService: photoLibraryItemsService
        )
        
        let viewController = PhotoLibraryViewController()
        
        let router = PhotoLibraryUIKitRouter(viewController: viewController)
        
        let presenter = PhotoLibraryPresenter(
            interactor: interactor,
            router: router
        )
        
        viewController.addDisposable(presenter)
        
        presenter.view = viewController
        configure(presenter)
        
        return viewController
    }
}
