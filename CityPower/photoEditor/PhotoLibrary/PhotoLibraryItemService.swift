//
//  PhotoLibraryItemService.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import Photos


extension PHPhotoLibrary {
    
    static func readWriteAuthorizationStatus() -> PHAuthorizationStatus {
        if #available(iOS 14, *) {
            return PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            return PHPhotoLibrary.authorizationStatus()
        }
    }
    
    static func requestReadWriteAuthorization(_ handler: @escaping (PHAuthorizationStatus) -> ()) {
        if #available(iOS 14, *) {
            return PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: handler)
        } else {
            return PHPhotoLibrary.requestAuthorization(handler)
        }
    }
}

protocol PhotoLibraryItemsService {
    func observeAuthorizationStatus(handler: @escaping (_ accessGranted: Bool) -> ())
    func observeAlbums(handler: @escaping ([PhotoLibraryAlbum]) -> ())
    func observeEvents(in: PhotoLibraryAlbum, handler: @escaping (_ event: PhotoLibraryAlbumEvent) -> ())
}

enum PhotosOrder {
    case normal
    case reversed
}

final class PhotoLibraryItemsServiceImpl: NSObject, PhotoLibraryItemsService, PHPhotoLibraryChangeObserver {
    
    private let photosOrder: PhotosOrder
    private let photoLibrary = PHPhotoLibrary.shared()
    private var fetchResults = [PhotoLibraryFetchResult]()
    
    private let fetchResultQueue = DispatchQueue(
        label: "com.CityPower.PhotoLibraryItemsServiceImpl.fetchResultQueue",
        qos: .userInitiated
    )
    
    private lazy var imageManager = PHImageManager()
    
    
    init(photosOrder: PhotosOrder = .normal) {
        self.photosOrder = photosOrder
    }
    
    deinit {
        photoLibrary.unregisterChangeObserver(self)
    }
    
    
    func observeAuthorizationStatus(handler: @escaping (_ accessGranted: Bool) -> ()) {
        onAuthorizationStatusChange = handler
        callAuthorizationHandler(for: PHPhotoLibrary.readWriteAuthorizationStatus())
    }
    
    func observeAlbums(handler: @escaping ([PhotoLibraryAlbum]) -> ()) {
        executeAfterSetup {
            self.onAlbumsChange = handler
            handler(self.allAlbums())
        }
    }
    
    func observeEvents(in album: PhotoLibraryAlbum, handler: @escaping (_ event: PhotoLibraryAlbumEvent) -> ()) {
        executeAfterSetup {
            self.observedAlbum = album
            self.onAlbumEvent = handler
            self.callObserverHandler(changes: nil)
        }
    }
    
    
    func photoLibraryDidChange(_ change: PHChange) {
        
        fetchResultQueue.async {
            guard self.fetchResults.count > 0 else { return }
            
            var needToReportAlbumsChange = false
            
            self.fetchResults.forEach { fetchResult in
                
                fetchResult.albums = fetchResult.albums.map { album in
                    guard let changeDetails = change.changeDetails(for: album.fetchResult) else { return album }
                    
                    var album = album
                    album.fetchResult = changeDetails.fetchResultAfterChanges
                    
                    let lastAssetImageSource = album.fetchResult.lastObject.flatMap { PHAssetImageSource(asset: $0) }
                    
                    if album.coverImage != lastAssetImageSource {
                        
                        album = album.changingCoverImage(to: lastAssetImageSource)
                        needToReportAlbumsChange = true
                    }
                    
                    if album == self.observedAlbum {
                        DispatchQueue.main.async {
                            self.callObserverHandler(changes: changeDetails)
                        }
                    }
                    
                    return album
                }
                
                if let collectionFetchResult = fetchResult.phFetchResult,
                   let changeDetails = change.changeDetails(for: collectionFetchResult)
                {
                    fetchResult.phFetchResult = changeDetails.fetchResultAfterChanges
                    
                    changeDetails.removedIndexes?.reversed().forEach { index in
                        fetchResult.albums.remove(at: index)
                    }
                    
                    changeDetails.insertedIndexes?.enumerated()
                        .map { ($1, changeDetails.insertedObjects[$0]) }
                        .forEach { insertionIndex, assetCollection in
                            let album = PhotoLibraryAlbum(assetCollection: assetCollection)
                            fetchResult.albums.insert(album, at: insertionIndex)
                        }
                    
                    changeDetails.changedIndexes?.enumerated()
                        .map { ($1, changeDetails.changedObjects[$0]) }
                        .forEach { changingIndex, assetCollection in
                            let album = PhotoLibraryAlbum(assetCollection: assetCollection)
                            fetchResult.albums[changingIndex] = album
                        }
                
                    needToReportAlbumsChange = true
                }
            }
            
            if needToReportAlbumsChange {
                let albums = self.allAlbums()
                DispatchQueue.main.async {
                    self.onAlbumsChange?(albums)
                }
            }
        }
    }
    
    private var onAlbumEvent: ((PhotoLibraryAlbumEvent) -> ())?
    private var onAlbumsChange: (([PhotoLibraryAlbum]) -> ())?
    private var onAuthorizationStatusChange: ((_ accessGranted: Bool) -> ())?
    
    private var observedAlbum: PhotoLibraryAlbum?
    private var wasSetUp = false
    
    private func executeAfterSetup(completion: @escaping () -> ()) {
        
        guard !wasSetUp else {
            completion()
            return
        }
        
        switch PHPhotoLibrary.readWriteAuthorizationStatus() {
        
        case .authorized:
            wasSetUp = true
            setUpFetchResult(completion: completion)
            
        case .limited:
            wasSetUp = true
            setUpFetchResultForLimitedAccess(completion: completion)
        
        case .notDetermined:
            PHPhotoLibrary.requestReadWriteAuthorization { [weak self] status in
                
                DispatchQueue.main.async {
                    self?.callAuthorizationHandler(for: status)
                    self?.wasSetUp = true
                }
                
                if case .authorized = status {
                    self?.setUpFetchResult(completion: completion)
                } else {
                    DispatchQueue.main.async(execute: completion)
                }
            }
            
        case .restricted, .denied:
            wasSetUp = true
            completion()
        
        @unknown default:
            assertionFailure("Unknown authorization status")
            wasSetUp = true
            completion()
        }
    }
    
    private func setUpFetchResult(completion: @escaping () -> ()) {
        fetchResultQueue.async {
            
            var fetchResults = [PhotoLibraryFetchResult]()
            
            let collectionsFetchResults = [
                PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil),
                PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            ]
            
            collectionsFetchResults.enumerated().forEach { index, collectionsFetchResult in
                
                var albums = [PhotoLibraryAlbum]()
                
                collectionsFetchResult.enumerateObjects(using: { collection, _, _ in
                    albums.append(PhotoLibraryAlbum(assetCollection: collection))
                })
                
                fetchResults.append(PhotoLibraryFetchResult(albums: albums, phFetchResult: collectionsFetchResult))
            }
            
            self.fetchResults = fetchResults
            self.photoLibrary.register(self)

            DispatchQueue.main.async(execute: completion)
        }
    }
    
    private func setUpFetchResultForLimitedAccess(completion: @escaping () -> ()) {
        
        fetchResultQueue.async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced]
            
            let assetsFetchResult = PHAsset.fetchAssets(with: fetchOptions)
            print("Assets in fetch result: \(assetsFetchResult.count)")
            
            let assetCollection = PHAssetCollection.transientAssetCollection(
                withAssetFetchResult: assetsFetchResult,
                title: "All photos"
            )

            let albums = [PhotoLibraryAlbum(assetCollection: assetCollection)]
            
            self.fetchResults = [PhotoLibraryFetchResult(albums: albums, phFetchResult: nil)]
            self.photoLibrary.register(self)

            DispatchQueue.main.async(execute: completion)
        }
    }
    
    private func callAuthorizationHandler(for status: PHAuthorizationStatus) {
        let isAccessGranted: Bool = {
            if #available(iOS 14, *) {
                return status == .authorized || status == .limited
            } else {
                return status == .authorized
            }
        }()
        onAuthorizationStatusChange?(isAccessGranted)
    }

    private func callObserverHandler(changes phChanges: PHFetchResultChangeDetails<PHAsset>?) {
        if let phChanges = phChanges, phChanges.hasIncrementalChanges {
            onAlbumEvent?(.incrementalChanges(photoLibraryChanges(from: phChanges)))
        } else if let observedAlbum = observedAlbum {
            onAlbumEvent?(.fullReload(photoLibraryItems(from: observedAlbum.fetchResult)))
        } else {
            onAlbumEvent?(.fullReload([]))
        }
    }
    
    private func photoLibraryItems(from fetchResult: PHFetchResult<PHAsset>) -> [PhotoLibraryItem] {
        
        let indexes = 0 ..< fetchResult.count
        
        return indexes.map { indexInFetchResult in
            
            let index: Int = {
                switch photosOrder {
                case .normal:
                    return indexInFetchResult
                case .reversed:
                    return indexes.upperBound - indexInFetchResult - 1
                }
            }()
            
            return PhotoLibraryItem(
                image: PHAssetImageSource(
                    fetchResult: fetchResult,
                    index: index,
                    imageManager: imageManager
                )
            )
        }
    }
    
    private func photoLibraryItem(from asset: PHAsset) -> PhotoLibraryItem {
        return PhotoLibraryItem(
            image: PHAssetImageSource(asset: asset, imageManager: imageManager)
        )
    }
    
    func photoLibraryChanges(from changes: PHFetchResultChangeDetails<PHAsset>)
        -> PhotoLibraryChanges
    {
        return PhotoLibraryChanges(
            removedIndexes: removedIndexes(from: changes),
            insertedItems: insertedObjects(from: changes),
            updatedItems: updatedObjects(from: changes),
            movedIndexes: movedIndexes(from: changes),
            itemsAfterChanges: photoLibraryItems(from: changes.fetchResultAfterChanges)
        )
    }
    
    private func removedIndexes(from changes: PHFetchResultChangeDetails<PHAsset>)
        -> IndexSet
    {
        let assetsCountBeforeChanges = changes.fetchResultBeforeChanges.count
        var removedIndexes = IndexSet()
        
        switch photosOrder {
        case .normal:
            changes.removedIndexes?.reversed().forEach { index in
                removedIndexes.insert(index)
            }
        case .reversed:
            changes.removedIndexes?.forEach { index in
                removedIndexes.insert(assetsCountBeforeChanges - index - 1)
            }
        }
        
        return removedIndexes
    }
    
    private func insertedObjects(from changes: PHFetchResultChangeDetails<PHAsset>)
        -> [(index: Int, item: PhotoLibraryItem)]
    {
        guard let insertedIndexes = changes.insertedIndexes else { return [] }
        
        let objectsCountAfterRemovalsAndInsertions =
            changes.fetchResultBeforeChanges.count - changes.removedObjects.count + changes.insertedObjects.count
        
        return insertedIndexes.enumerated().map {
            insertionIndex, targetAssetIndex -> (index: Int, item: PhotoLibraryItem) in
            
            let asset = changes.insertedObjects[insertionIndex]
            
            let finalAssetIndex: Int = {
                switch photosOrder {
                case .normal:
                    return targetAssetIndex
                case .reversed:
                    return objectsCountAfterRemovalsAndInsertions - targetAssetIndex - 1
                }
            }()
            
            return (index: finalAssetIndex, item: photoLibraryItem(from: asset))
        }
    }
    
    private func updatedObjects(from changes: PHFetchResultChangeDetails<PHAsset>)
        -> [(index: Int, item: PhotoLibraryItem)]
    {
        guard let changedIndexes = changes.changedIndexes else { return [] }
        
        let objectsCountAfterRemovalsAndInsertions =
            changes.fetchResultBeforeChanges.count - changes.removedObjects.count + changes.insertedObjects.count
        
        return changedIndexes.enumerated().map { changeIndex, assetIndex -> (index: Int, item: PhotoLibraryItem) in
            
            let asset = changes.changedObjects[changeIndex]
            
            let finalAssetIndex: Int = {
                switch photosOrder {
                case .normal:
                    return assetIndex
                case .reversed:
                    return objectsCountAfterRemovalsAndInsertions - assetIndex - 1
                }
            }()
            
            return (index: finalAssetIndex, item: photoLibraryItem(from: asset))
        }
    }
    
    private func movedIndexes(from changes: PHFetchResultChangeDetails<PHAsset>)
        -> [(from: Int, to: Int)]
    {
        var movedIndexes = [(from: Int, to: Int)]()
        
        let objectsCountAfterRemovalsAndInsertions =
            changes.fetchResultBeforeChanges.count - changes.removedObjects.count + changes.insertedObjects.count
        
        changes.enumerateMoves { from, to in
            
            let (realFrom, realTo): (Int, Int) = {
                switch self.photosOrder {
                case .normal:
                    return (from, to)
                case .reversed:
                    return (
                        objectsCountAfterRemovalsAndInsertions - from - 1,
                        objectsCountAfterRemovalsAndInsertions - to - 1
                    )
                }
            }()
            
            movedIndexes.append((from: realFrom, to: realTo))
        }
        
        return movedIndexes
    }
    
    private func allAlbums() -> [PhotoLibraryAlbum] {
        
        var albums = fetchResults.flatMap { $0.albums }

        if let allPhotosAlbumIndex = albums.firstIndex(where: { $0.isAllPhotos }), allPhotosAlbumIndex > 0 {
            albums.insert(albums.remove(at: allPhotosAlbumIndex), at: 0)
        }
        
        return albums
    }
}

private final class PhotoLibraryFetchResult {
    
    var albums: [PhotoLibraryAlbum]
    var phFetchResult: PHFetchResult<PHAssetCollection>?
    
    init(albums: [PhotoLibraryAlbum], phFetchResult: PHFetchResult<PHAssetCollection>?) {
        self.albums = albums
        self.phFetchResult = phFetchResult
    }
}


final class PhotoLibraryAlbum: Equatable {
    
    let identifier: String
    let title: String?
    let coverImage: ImageSource?
    let numberOfItems: Int
    let isAllPhotos: Bool
    
    fileprivate var fetchResult: PHFetchResult<PHAsset>

    private init(
        identifier: String,
        title: String?,
        coverImage: ImageSource?,
        isAllPhotos: Bool,
        fetchResult: PHFetchResult<PHAsset>)
    {
        self.identifier = identifier
        self.title = title
        self.coverImage = coverImage
        self.fetchResult = fetchResult
        self.isAllPhotos = isAllPhotos
        self.numberOfItems = fetchResult.count
    }
    
    fileprivate convenience init(assetCollection: PHAssetCollection) {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
        
        let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
        
        self.init(
            identifier: assetCollection.localIdentifier,
            title: assetCollection.localizedTitle,
            coverImage: fetchResult.lastObject.flatMap { PHAssetImageSource(asset: $0) },
            isAllPhotos: assetCollection.assetCollectionType == .smartAlbum &&
                         assetCollection.assetCollectionSubtype == .smartAlbumUserLibrary,
            fetchResult: fetchResult
        )
    }
    
    func changingCoverImage(to image: ImageSource?) -> PhotoLibraryAlbum {
        return PhotoLibraryAlbum(
            identifier: identifier,
            title: title,
            coverImage: image,
            isAllPhotos: isAllPhotos,
            fetchResult: fetchResult
        )
    }
    
    static func ==(lhs: PhotoLibraryAlbum, rhs: PhotoLibraryAlbum) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}