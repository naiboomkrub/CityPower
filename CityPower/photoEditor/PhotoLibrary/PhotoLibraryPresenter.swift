//
//  PhotoLibraryPresenter.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit


protocol PhotoLibraryRouter: class {
    func dismissCurrentModule()
}

final class PhotoLibraryUIKitRouter: BaseUIKitRouter, PhotoLibraryRouter {
}


final class PhotoLibraryPresenter: PhotoLibraryModule {
    
    private let interactor: PhotoLibraryInteractor
    private let router: PhotoLibraryRouter
    
    weak var view: PhotoLibraryViewInput? {
        didSet {
            view?.onViewDidLoad = { [weak self] in
                self?.setUpView()
            }
        }
    }
    
    var shouldScrollToBottomOnFullReload = true
    
    init(interactor: PhotoLibraryInteractor, router: PhotoLibraryRouter) {
        self.interactor = interactor
        self.router = router
    }
    
    var onFinish: ((PhotoLibraryModuleResult) -> ())?
    
    func dismissModule() {
        router.dismissCurrentModule()
    }
    
    private func setUpView() {
        
        view?.setTitleVisible(false)
        view?.setPlaceholderState(.hidden)
        view?.setProgressVisible(true)
        
        interactor.observeAuthorizationStatus { [weak self] accessGranted in
            self?.view?.setAccessDeniedViewVisible(!accessGranted)
            
            if !accessGranted {
                self?.view?.setProgressVisible(false)
            }
        }
        
        interactor.observeAlbums { [weak self] albums in
            guard let strongSelf = self else { return }
            
            let albums = albums.filter { $0.numberOfItems > 0 }
            
            self?.view?.setAlbums(albums.map(strongSelf.albumCellData))
            
            if let currentAlbum = strongSelf.interactor.currentAlbum, albums.contains(currentAlbum) {
                self?.adjustView(for: currentAlbum)
            } else if let album = albums.first {
                self?.selectAlbum(album)
            } else {
                self?.view?.setTitleVisible(false)
                self?.view?.setPlaceholderState(.visible(title: "No photos"))
                self?.view?.setProgressVisible(false)
            }
        }
        
        interactor.observeCurrentAlbumEvents { [weak self] event, selectionState in
            guard let strongSelf = self else { return }
            
            var needToShowPlaceholder: Bool
            
            switch event {
            case .fullReload(let items):
                needToShowPlaceholder = items.isEmpty
                self?.view?.setItems(
                    items.map(strongSelf.cellData),
                    scrollToBottom: strongSelf.shouldScrollToBottomOnFullReload,
                    completion: {
                        self?.shouldScrollToBottomOnFullReload = false
                        self?.adjustViewForSelectionState(selectionState)
                        self?.view?.setProgressVisible(false)
                    }
                )
                
            case .incrementalChanges(let changes):
                needToShowPlaceholder = changes.itemsAfterChanges.isEmpty
                self?.view?.applyChanges(strongSelf.viewChanges(from: changes), completion: {
                    self?.adjustViewForSelectionState(selectionState)
                })
            }
            
            self?.view?.setPlaceholderState(
                needToShowPlaceholder ? .visible(title: "Album is empty") : .hidden
            )
        }
        
        view?.onPickButtonTap = { [weak self] in
            if let strongSelf = self {
                self?.onFinish?(.selectedItems(strongSelf.interactor.selectedItems))
            }
        }
        
        view?.onCancelButtonTap = { [weak self] in
            self?.onFinish?(.cancelled)
        }
        
        view?.onAccessDeniedButtonTap = {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        
        view?.onTitleTap = { [weak self] in
            self?.view?.toggleAlbumsList()
        }
        
        view?.onDimViewTap = { [weak self] in
            self?.view?.hideAlbumsList()
        }
    }
    
    private func appName() -> String {
        return Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? ""
    }
    
    private func adjustViewForSelectionState(_ state: PhotoLibraryItemSelectionState) {
        view?.setDimsUnselectedItems(!state.canSelectMoreItems)
        view?.setCanSelectMoreItems(state.canSelectMoreItems)
        
        switch state.preSelectionAction {
        case .none:
            break
        case .deselectAll:
            view?.deselectAllItems()
        }
    }
    
    private func albumCellData(for album: PhotoLibraryAlbum) -> PhotoLibraryAlbumCellData {
        return PhotoLibraryAlbumCellData(
            identifier: album.identifier,
            title: album.title ?? "Unnamed album",
            coverImage: album.coverImage,
            onSelect: { [weak self] in
                self?.selectAlbum(album)
                self?.view?.hideAlbumsList()
            }
        )
    }
    
    private func selectAlbum(_ album: PhotoLibraryAlbum) {
        shouldScrollToBottomOnFullReload = true
        interactor.setCurrentAlbum(album)
        adjustView(for: album)
    }
    
    private func adjustView(for album: PhotoLibraryAlbum) {
        view?.setTitle(album.title ?? "Unnamed album")
        view?.setTitleVisible(true)
        view?.selectAlbum(withId: album.identifier)
    }
    
    private func cellData(_ item: PhotoLibraryItem) -> PhotoLibraryItemCellData {
        
        var cellData = PhotoLibraryItemCellData(image: item.image)

        cellData.selected = interactor.isSelected(item)
        
        cellData.onSelectionPrepare = { [weak self] in
            if let selectionState = self?.interactor.prepareSelection() {
                self?.adjustViewForSelectionState(selectionState)
            }
        }
        
        cellData.onSelect = { [weak self] in
            if let selectionState = self?.interactor.selectItem(item) {
                self?.adjustViewForSelectionState(selectionState)
            }
        }
        
        cellData.onDeselect = { [weak self] in
            if let selectionState = self?.interactor.deselectItem(item) {
                self?.adjustViewForSelectionState(selectionState)
            }
        }
        
        return cellData
    }
    
    private func viewChanges(from changes: PhotoLibraryChanges) -> PhotoLibraryViewChanges {
        return PhotoLibraryViewChanges(
            removedIndexes: changes.removedIndexes,
            insertedItems: changes.insertedItems.map { (index: $0, cellData: cellData($1)) },
            updatedItems: changes.updatedItems.map { (index: $0, cellData: cellData($1)) },
            movedIndexes: changes.movedIndexes
        )
    }
}
