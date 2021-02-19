//
//  ThumbnailView.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit

final class ThumbnailsView: UIView, UICollectionViewDataSource, MediaRibbonLayoutDelegate {
    
    var onDragStart: (() -> ())? {
        get {
            return layout.onDragStart
        }
        set {
            layout.onDragStart = newValue
        }
    }
    
    var onDragFinish: (() -> ())? {
        get {
            return layout.onDragFinish
        }
        set {
            layout.onDragFinish = newValue
        }
    }
    
    private let layout: ThumbnailsViewLayout
    private let collectionView: UICollectionView
    private let dataSource = MediaRibbonDataSource()
    
    private let mediaRibbonInteritemSpacing = CGFloat(7)
    
    private let photoCellReuseId = "PhotoCell"
    private let cameraCellReuseId = "CameraCell"
    
    init() {
        
        layout = ThumbnailsViewLayout()
        layout.spacing = mediaRibbonInteritemSpacing
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.clipsToBounds = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(MediaItemThumbnailCell.self, forCellWithReuseIdentifier: photoCellReuseId)
        collectionView.register(CameraThumbnailCell.self, forCellWithReuseIdentifier: cameraCellReuseId)
        
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
    
    
    var cameraOutputParameters: CameraOutputParameters? {
        didSet {
            updateCameraCell()
        }
    }
    
    var contentInsets = UIEdgeInsets.zero {
        didSet {
            layout.sectionInset = contentInsets
        }
    }
    
    var onPhotoItemSelect: ((MediaPickerItem) -> ())?
    var onItemMove: ((Int, Int) -> ())?
    var onCameraItemSelect: (() -> ())?
    
    func selectCameraItem() {
        collectionView.selectItem(at: dataSource.indexPathForCameraItem(), animated: false, scrollPosition: [])
    }
    
    func selectMediaItem(_ item: MediaPickerItem, animated: Bool = false) {
        layout.cancelDrag()
        
        if let indexPath = dataSource.indexPathForItem(item) {
            collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: [])
        }
    }
    
    func scrollToItemThumbnail(_ item: MediaPickerItem, animated: Bool) {
        if let indexPath = dataSource.indexPathForItem(item) {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally,
                animated: animated
            )
        }
    }
    
    func scrollToCameraThumbnail(animated: Bool) {
        collectionView.scrollToItem(
            at: dataSource.indexPathForCameraItem(),
            at: .centeredHorizontally,
            animated: animated
        )
    }
        
    func setHapticFeedbackEnabled(_ enabled: Bool) {
        layout.hapticFeedbackEnabled = enabled
    }
    
    func addItems(_ items: [MediaPickerItem], animated: Bool, completion: @escaping () -> ()) {
        collectionView.performBatchUpdates( animated: animated, updates: { [weak self] in
                
            if let indexPaths = self?.dataSource.addItems(items) {
                self?.collectionView.insertItems(at: indexPaths)
                    
                if let indexPathsToReload = self?.collectionView.indexPathsForVisibleItems.filter({ !indexPaths.contains($0) }),
                    indexPathsToReload.count > 0
                {
                    self?.collectionView.reloadItems(at: indexPathsToReload)
                }
            }
        },
        completion: { _ in
            completion()
        }
    )
}
    
    func updateItem(_ item: MediaPickerItem) {
        
        if let indexPath = dataSource.updateItem(item) {
            
            let selectedIndexPaths = collectionView.indexPathsForSelectedItems
            let cellWasSelected = selectedIndexPaths?.contains(indexPath) == true
            
            collectionView.reloadItems(at: [indexPath])
            
            if cellWasSelected {
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
        }
    }
    
    func removeItem(_ item: MediaPickerItem, animated: Bool) {
        collectionView.deleteItems(animated: animated) { [weak self] in
            self?.dataSource.removeItem(item).flatMap { [$0] }
        }
    }
    
    func setCameraItemVisible(_ visible: Bool) {
        
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
    
    func setCameraOutputParameters(_ parameters: CameraOutputParameters) {
        cameraOutputParameters = parameters
    }
    
    func setCameraOutputOrientation(_ orientation: ExifOrientation) {
        cameraOutputParameters?.orientation = orientation
        if let cell = cameraCell() {
            cell.setOutputOrientation(orientation)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch dataSource[indexPath] {
        case .camera:
            return cameraCell(forIndexPath: indexPath, inCollectionView: collectionView)
        case .photo(let mediaPickerItem):
            return photoCell(forIndexPath: indexPath, inCollectionView: collectionView, withItem: mediaPickerItem)
        }
    }
    
    func shouldApplyTransformToItemAtIndexPath(_ indexPath: IndexPath) -> Bool {
        switch dataSource[indexPath] {
        case .photo:
            return true
        case .camera:
            return false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch dataSource[indexPath] {
        case .photo(let photo):
            onPhotoItemSelect?(photo)
        case .camera:
            onCameraItemSelect?()
        }
    }
    
    func canMove(to indexPath: IndexPath) -> Bool {
        let cameraCellVisible = dataSource.cameraCellVisible ? 1 : 0
        
        let lastSectionIndex = collectionView.numberOfSections - 1
        let lastItemIndex = collectionView.numberOfItems(inSection: lastSectionIndex) - cameraCellVisible
        let lastIndexPath = IndexPath(item: lastItemIndex, section: lastSectionIndex)
        
        return indexPath != lastIndexPath
    }
    
    func moveItem(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        onItemMove?(sourceIndexPath.item, destinationIndexPath.item)
        dataSource.moveItem(from: sourceIndexPath.item, to: destinationIndexPath.item)
    }
    
    private func photoCell(forIndexPath indexPath: IndexPath, inCollectionView collectionView: UICollectionView, withItem mediaPickerItem: MediaPickerItem) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: photoCellReuseId,
            for: indexPath
        )
        
        if let cell = cell as? MediaItemThumbnailCell {
            cell.customizeWithItem(mediaPickerItem)
        }
        
        return cell
    }
    
    private func cameraCell(forIndexPath indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell( withReuseIdentifier: cameraCellReuseId, for: indexPath)
        
        setUpCameraCell(cell)
        
        return cell
    }
    
    private func setUpCameraCell(_ cell: UICollectionViewCell) {
        if let cell = cell as? CameraThumbnailCell {
            
            if let cameraOutputParameters = cameraOutputParameters, !isHidden {
                cell.setOutputParameters(cameraOutputParameters)
            }
        }
    }
    
    private func updateCameraCell() {
        if let cell = cameraCell() {
            setUpCameraCell(cell)
        }
    }
    
    private func cameraCell() -> CameraThumbnailCell? {
        let indexPath = dataSource.indexPathForCameraItem()
        return collectionView.cellForItem(at: indexPath) as? CameraThumbnailCell
    }
}


final class MediaItemThumbnailCell: PhotoCollectionViewCell, Customizable {
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 6
        layer.masksToBounds = true
        
        imageView.layer.cornerRadius = 6
        imageView.layer.masksToBounds = true
        imageViewInsets = UIEdgeInsets(top: 0.5, left: 0.5, bottom: 0.5, right: 0.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isSelected = false
    }

    func customizeWithItem(_ item: MediaPickerItem) {
        imageSource = item.image
    }
}


final class CameraThumbnailCell: UICollectionViewCell {
    
    private let button = UIButton()
    private var cameraOutputView: CameraOutputView?
    
    func setOutputParameters(_ parameters: CameraOutputParameters) {
        
        let newCameraOutputView = CameraOutputView(captureSession: parameters.captureSession, outputOrientation: parameters.orientation)
        newCameraOutputView.layer.cornerRadius = 6
        
        newCameraOutputView.alpha = 0.0
        
        cameraOutputView?.removeFromSuperview()
        insertSubview(newCameraOutputView, belowSubview: button)
        
        self.cameraOutputView = newCameraOutputView
        self.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        
        UIView.animate(withDuration: 0.5) {
            newCameraOutputView.alpha = 1.0
        }
    
    }
    
    func setOutputOrientation(_ orientation: ExifOrientation) {
        cameraOutputView?.orientation = orientation
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .black
        layer.cornerRadius = 6
        layer.masksToBounds = true
        layer.borderColor = UIColor.lightBlueCity.cgColor
        
        button.setImage(UIImage(named: "camera"), for: .normal)
        button.tintColor = .white
        button.isUserInteractionEnabled = false
    
        addSubview(button)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            layer.borderWidth = isSelected ? 4 : 0
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let insets = UIEdgeInsets(top: 0.5, left: 0.5, bottom: 0.5, right: 0.5)
        cameraOutputView?.frame = bounds.inset(by: insets)
        
        button.frame = bounds
    }
}


class PhotoCollectionViewCell: UIImageSourceCollectionViewCell {
    
    var selectedBorderThickness: CGFloat = 4
      
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.borderColor = UIColor.lightBlueCity.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            layer.borderWidth = isSelected ? selectedBorderThickness : 0
        }
    }
}


final class MediaRibbonDataSource {
    
    typealias DataMutationHandler = (_ indexPaths: [IndexPath], _ mutatingFunc: () -> ()) -> ()
    
    private var mediaPickerItems = [MediaPickerItem]()
    
    var cameraCellVisible: Bool = true
    
    var numberOfItems: Int {
        return mediaPickerItems.count + (cameraCellVisible ? 1 : 0)
    }
    
    subscript(indexPath: IndexPath) -> MediaRibbonItem {
        if indexPath.item < mediaPickerItems.count {
            return .photo(mediaPickerItems[indexPath.item])
        } else {
            return .camera
        }
    }
    
    func addItems(_ items: [MediaPickerItem]) -> [IndexPath] {
        
        let items = items.filter { !mediaPickerItems.contains($0) }
        
        let insertedIndexes = mediaPickerItems.count ..< mediaPickerItems.count + items.count
        let indexPaths = insertedIndexes.map { IndexPath(item: $0, section: 0) }
        
        mediaPickerItems.append(contentsOf: items)
        
        return indexPaths
    }
    
    func updateItem(_ item: MediaPickerItem) -> IndexPath? {
        if let index = mediaPickerItems.firstIndex(of: item) {
            mediaPickerItems[index] = item
            return IndexPath(item: index, section: 0)
        } else {
            return nil
        }
    }
    
    func removeItem(_ item: MediaPickerItem) -> IndexPath? {
        if let index = mediaPickerItems.firstIndex(of: item) {
            mediaPickerItems.remove(at: index)
            return IndexPath(item: index, section: 0)
        } else {
            return nil
        }
    }
    
    func moveItem(from index: Int, to destinationIndex: Int) {
        mediaPickerItems.moveElement(from: index, to: destinationIndex)
    }
    
    func indexPathForItem(_ item: MediaPickerItem) -> IndexPath? {
        return mediaPickerItems.firstIndex(of: item).flatMap { IndexPath(item: $0, section: 0) }
    }
    
    func indexPathForCameraItem() -> IndexPath {
        return IndexPath(item: mediaPickerItems.count, section: 0)
    }
}

enum MediaRibbonItem {
    case photo(MediaPickerItem)
    case camera
}


extension Array {
    
    func element(at index: Int) -> Element? {
        if 0 <= index && index < count {
            return self[index]
        } else {
            return nil
        }
    }
    
    mutating func moveElement(from sourceIndex: Int, to destinationIndex: Int) {
        if let itemToMove = self.element(at: sourceIndex), 0 <= destinationIndex && destinationIndex < count {
            self.remove(at: sourceIndex)
            self.insert(itemToMove, at: destinationIndex)
        }
    }
}


extension UICollectionView {
    
    func performBatchUpdates(updates: @escaping () -> Void) {
        performBatchUpdates(updates, completion: nil)
    }
    
    func performNonAnimatedBatchUpdates(updates: @escaping () -> Void, completion: ((Bool) -> ())? = nil) {
        UIView.animate(withDuration: 0) {
            self.performBatchUpdates(updates, completion: completion)
        }
    }
    
    func performBatchUpdates(animated: Bool, updates: @escaping () -> Void, completion: ((Bool) -> ())? = nil) {
        let updateCollectionView = animated ? performBatchUpdates : performNonAnimatedBatchUpdates
        updateCollectionView(updates, completion)
    }
    
    func insertItems(animated: Bool, _ updates: @escaping () -> [IndexPath]?) {
        performBatchUpdates(animated: animated, updates: { [weak self] in
            if let indexPaths = updates() {
                self?.insertItems(at: indexPaths)
            }
        })
    }
    
    func deleteItems(animated: Bool, _ updates: @escaping () -> [IndexPath]?) {
        performBatchUpdates(animated: animated, updates: { [weak self] in
            if let indexPaths = updates() {
                self?.deleteItems(at: indexPaths)
            }
        })
    }
}




final class CollectionViewDataSource<CellType: Customizable>: NSObject, UICollectionViewDataSource {
    
    typealias ItemType = CellType.ItemType
    
    let cellReuseIdentifier: String
    let headerReuseIdentifier: String?
    
    var additionalCellConfiguration: ((CellType, ItemType, UICollectionView, IndexPath) -> ())?
    var configureHeader: ((UIView) -> ())?
    
    private var items = [ItemType]()
    
    init(cellReuseIdentifier: String, headerReuseIdentifier: String? = nil) {
        self.cellReuseIdentifier = cellReuseIdentifier
        self.headerReuseIdentifier = headerReuseIdentifier
    }
    
    func item(at indexPath: IndexPath) -> ItemType {
        return items[indexPath.item]
    }
    
    func safeItem(at indexPath: IndexPath) -> ItemType? {
        return indexPath.item < items.count ? items[indexPath.item] : nil
    }
    
    func replaceItem(at indexPath: IndexPath, with item: ItemType) {
        items[indexPath.item] = item
    }
    
    func insertItems(_ items: [(item: ItemType, indexPath: IndexPath)]) {
        let sortedItems = items.sorted { $0.indexPath.row < $1.indexPath.row }
        
        sortedItems.forEach { item in
            if item.indexPath.row > self.items.count {
                self.items.append(item.item)
            } else {
                self.items.insert(item.item, at: item.indexPath.row)
            }
        }
    }
    
    func deleteAllItems() {
        items = []
    }
    
    func deleteItems(at indexPaths: [IndexPath]) {
        indexPaths.map { $0.item }.sorted().reversed().forEach { row in
            items.remove(at: row)
        }
    }
    
    func moveItem(at fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        guard fromIndexPath != toIndexPath else { return }
        
        let fromIndex = fromIndexPath.item
        let toIndex = toIndexPath.item
        
        let item = items.remove(at: fromIndex)
        
        if toIndex > fromIndex {
            items.insert(item, at: toIndex - 1)
        } else {
            items.insert(item, at: toIndex)
        }
    }
    
    func addItem(_ item: ItemType) {
        items.append(item)
    }

    func setItems(_ items: [ItemType]) {
        self.items = items
    }
    
    func mutateItem(at indexPath: IndexPath, mutate: (inout ItemType) -> ()) {
        if var item = safeItem(at: indexPath) {
            mutate(&item)
            replaceItem(at: indexPath, with: item)
        }
    }
    
    func mutateItem<ItemType: Equatable>(_ theItem: ItemType, at indexPath: IndexPath, mutate: (inout ItemType) -> ())
        where ItemType == CellType.ItemType
    {
        mutateItem(at: indexPath) { (item: inout ItemType) in
            if item == theItem {
                mutate(&item)
            }
        }
    }
    
    func indexPath(where findItem: (ItemType) -> Bool) -> IndexPath? {
        return items.firstIndex(where: findItem).flatMap { IndexPath(item: $0, section: 0) }
    }
    
    func indexPaths(where findItem: (ItemType) -> Bool) -> [IndexPath] {
        return items.enumerated()
            .compactMap { findItem($0.element) ? $0.offset : nil }
            .map { IndexPath(item: $0, section: 0) }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        let item = self.item(at: indexPath)
        
        if let cell = cell as? CellType {
            cell.customizeWithItem(item)
            additionalCellConfiguration?(cell, item, collectionView, indexPath)
        }
        
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath) -> UICollectionReusableView
    {
        guard let headerReuseIdentifier = headerReuseIdentifier, kind == UICollectionView.elementKindSectionHeader else {
            preconditionFailure("Invalid supplementary view type for this collection view")
        }
        
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: headerReuseIdentifier,
            for: indexPath
        )
        assert(configureHeader != nil)
        configureHeader?(view)
        return view
    }
}

protocol Customizable {
    associatedtype ItemType
    
    func customizeWithItem(_ item: ItemType)
}
