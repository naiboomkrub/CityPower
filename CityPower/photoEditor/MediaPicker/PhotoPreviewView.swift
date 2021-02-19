//
//  PhotoPreviewView.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit


final class PhotoPreviewView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var onSwipeToItem: ((MediaPickerItem) -> ())?
    var onSwipeToCamera: (() -> ())?
    var onSwipeToCameraProgressChange: ((CGFloat) -> ())?
    var hapticFeedbackEnabled = false
    var cameraView: UIView?
    
    private let collectionView: UICollectionView
    private let dataSource = MediaRibbonDataSource()

    private let photoCellReuseId = "PhotoCell"
    private let cameraCellReuseId = "CameraCell"
    
    init() {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = .zero
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.allowsSelection = false
        collectionView.register(PhotoPreviewCell.self, forCellWithReuseIdentifier: photoCellReuseId)
        collectionView.register(MainCameraCell.self, forCellWithReuseIdentifier: cameraCellReuseId)
        
        super.init(frame: .zero)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        addSubview(collectionView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
    }
    
    func scrollToCamera(animated: Bool = false) {
        let indexPath = dataSource.indexPathForCameraItem()
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
    
    func scrollToMediaItem(_ item: MediaPickerItem, animated: Bool = false) {
        if let indexPath = dataSource.indexPathForItem(item) {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        }
    }
    
    func addItems(_ items: [MediaPickerItem]) {
        let insertedIndexPaths = dataSource.addItems(items)
        addCollectionViewItemsAtIndexPaths(insertedIndexPaths)
    }
    
    func updateItem(_ item: MediaPickerItem) {
        if let indexPath = dataSource.updateItem(item) {
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    func removeItem(_ item: MediaPickerItem, animated: Bool) {
        collectionView.deleteItems(animated: animated) { [weak self] in
            let removedIndexPath = self?.dataSource.removeItem(item)
            return removedIndexPath.flatMap { [$0] }
        }
    }
    
    func moveItem(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex else { return }
        
        if hapticFeedbackEnabled {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        
        collectionView.performBatchUpdates(animated: false, updates: { [weak self] in
            self?.dataSource.moveItem(from: sourceIndex, to: destinationIndex)
            self?.collectionView.moveItem(
                at: IndexPath(item: sourceIndex, section: 0),
                to: IndexPath(item: destinationIndex, section: 0)
            )
        })
    }
    
    func setCameraVisible(_ visible: Bool) {
        
        if dataSource.cameraCellVisible != visible {
            
            let updatesFunction = { [weak self] () -> [IndexPath]? in
                self?.dataSource.cameraCellVisible = visible
                return (self?.dataSource.indexPathForCameraItem()).flatMap { [$0] }
            }
            
            if visible {
                collectionView.insertItems(animated: false, updatesFunction)
            } else {
                collectionView.deleteItems(animated: false, updatesFunction)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch dataSource[indexPath] {
        
        case .camera:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cameraCellReuseId, for: indexPath)
            
            if let cell = cell as? MainCameraCell {
                cell.cameraView = cameraView
            }
            
            return cell
        
        case .photo(let mediaPickerItem):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellReuseId, for: indexPath)
            
            if let cell = cell as? PhotoPreviewCell {
                cell.customizeWithItem(mediaPickerItem)
            }
            
            return cell
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    private var lastOffset: CGFloat?
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard lastOffset != nil else {
            self.lastOffset = scrollView.contentOffset.x
            return
        }
        
        let offset = scrollView.contentOffset.x
        let pageWidth = scrollView.bounds.width
        let numberOfPages = CGFloat(dataSource.numberOfItems)
        
        let penultimatePageOffsetX = pageWidth * (numberOfPages - 2)
        
        let progress = min(1, (offset - penultimatePageOffsetX) / pageWidth)
        
        if dataSource.cameraCellVisible {
            onSwipeToCameraProgressChange?(progress)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            onSwipeFinished()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        onSwipeFinished()
    }
    
    
    private var currentPage: Int {
        
        if collectionView.bounds.width > 0 {

            let pageRatio: CGFloat = collectionView.contentOffset.x / collectionView.bounds.width
            let maxPage = dataSource.numberOfItems - 1
            return max(0, min(maxPage, Int(round(pageRatio))))
        } else {
            return 0
        }
    }
    
    private func onSwipeFinished() {
        
        let indexPath = IndexPath(item: currentPage, section: 0)
        
        switch dataSource[indexPath] {
        case .photo(let item):
            onSwipeToItem?(item)
        case .camera:
            onSwipeToCamera?()
        }
    }
    
    private func addCollectionViewItemsAtIndexPaths(_ indexPaths: [IndexPath]) {
        
        let indexesOfInsertedPages = indexPaths.map { $0.row }
        
        let indexPath = IndexPath(item: indexOfPage(currentPage, afterInsertingPagesAtIndexes: indexesOfInsertedPages), section: 0)

        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: indexPath, at: [], animated: false)
    }
    
    private func indexOfPage(_ initialIndex: Int, afterInsertingPagesAtIndexes insertedIndexes: [Int]) -> Int {
        
        let sortedIndexes = insertedIndexes.sorted(by: <)
        var targetIndex = initialIndex
        
        for index in sortedIndexes {
            if index <= targetIndex {
                targetIndex += 1
            } else {
                break
            }
        }
        
        return max(0, min(dataSource.numberOfItems - 1, targetIndex))
    }
}


final class MainCameraCell: UICollectionViewCell {

    var cameraView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            
            if let cameraView = cameraView {
                addSubview(cameraView)
            }
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
        cameraView?.frame = contentView.bounds
    }
}


final class PhotoPreviewCell: PhotoCollectionViewCell {
    
    private let progressIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.contentMode = .scaleAspectFit
        
        progressIndicator.hidesWhenStopped = true
        progressIndicator.color = UIColor(red: 162.0 / 255, green: 162.0 / 255, blue: 162.0 / 255, alpha: 1)
        
        addSubview(progressIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        progressIndicator.center = CGPoint(x: bounds.maxX/2, y: bounds.maxY/2)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        setProgressVisible(false)
    }
    
    override func adjustImageRequestOptions(_ options: inout ImageRequestOptions) {
        super.adjustImageRequestOptions(&options)
        
        options.onDownloadStart = { [weak self, superOptions = options] requestId in
            superOptions.onDownloadStart?(requestId)
            self?.imageRequestId = requestId
            self?.setProgressVisible(true)
        }
        
        options.onDownloadFinish = { [weak self, superOptions = options] requestId in
            superOptions.onDownloadFinish?(requestId)
            if requestId == self?.imageRequestId {
                self?.setProgressVisible(false)
            }
        }
    }
    
    func customizeWithItem(_ item: MediaPickerItem) {
        imageSource = item.image
    }
    
    private var imageRequestId: ImageRequestId?
    
    private func setProgressVisible(_ visible: Bool) {
        if visible {
            progressIndicator.startAnimating()
        } else {
            progressIndicator.stopAnimating()
        }
    }
}

