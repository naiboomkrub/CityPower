//
//  PhotoLibraryView.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit



extension UIScrollView {
    
    func scrollToBottom() {
        layoutIfNeeded()
        let minimumYOffset = -max(safeAreaInsets.top, contentInset.top)
        contentOffset = CGPoint(
            x: 0,
            y: max(minimumYOffset, bounds.minY + contentSize.height + contentInset.top - bounds.size.height)
        )
    }
    
    func scrollToTop() {
        layoutIfNeeded()
        contentOffset = CGPoint(
            x: 0,
            y: -max(safeAreaInsets.top, contentInset.top)
        )
    }
}


protocol PhotoLibraryViewInput: class {
    
    var onTitleTap: (() -> ())? { get set }
    var onDimViewTap: (() -> ())? { get set }
   
    func setTitle(_: String)
    func setTitleVisible(_: Bool)
    
    func setPlaceholderState(_: PhotoLibraryPlaceholderState)
    
    func setItems(_: [PhotoLibraryItemCellData], scrollToBottom: Bool, completion: (() -> ())?)
    func applyChanges(_: PhotoLibraryViewChanges, completion: (() -> ())?)
    
    func setCanSelectMoreItems(_: Bool)
    func setDimsUnselectedItems(_: Bool)
    
    func deselectAllItems()
    
    func scrollToBottom()
    
    func setAlbums(_: [PhotoLibraryAlbumCellData])
    func selectAlbum(withId: String)
    func showAlbumsList()
    func hideAlbumsList()
    func toggleAlbumsList()
    
    var onPickButtonTap: (() -> ())? { get set }
    var onCancelButtonTap: (() -> ())? { get set }
    
    var onViewDidLoad: (() -> ())? { get set }
    
    func setProgressVisible(_ visible: Bool)
    
    var onAccessDeniedButtonTap: (() -> ())? { get set }

    func setAccessDeniedViewVisible(_: Bool)

}


struct PhotoLibraryViewChanges {
    let removedIndexes: IndexSet
    let insertedItems: [(index: Int, cellData: PhotoLibraryItemCellData)]
    let updatedItems: [(index: Int, cellData: PhotoLibraryItemCellData)]
    let movedIndexes: [(from: Int, to: Int)]
}

enum PhotoLibraryPlaceholderState {
    case hidden
    case visible(title: String)
}



final class ObjCExceptionCatcher {
    static func tryClosure(
        tryClosure: () -> (),
        catchClosure: @escaping (NSException) -> (),
        finallyClosure: @escaping () -> () = {})
    {
        AvitoMediaPicker_ObjCExceptionCatcherHelper.`try`(tryClosure, catch: catchClosure, finally: finallyClosure)
    }
}


final class PhotoLibraryView: UIView, UICollectionViewDelegateFlowLayout {
    
    private enum AlbumsListState {
        case collapsed
        case expanded
    }
    
    private var albumsListState: AlbumsListState = .collapsed
    
    var canSelectMoreItems = false
    
    var dimsUnselectedItems = false {
        didSet {
            adjustDimmingForVisibleCells()
        }
    }
    
    private let layout = PhotoLibraryLayout()
    private var collectionView: UICollectionView
    private var collectionSnapshotView: UIView?
    private let titleView = PhotoLibraryTitleView()
    private let accessDeniedView = AccessDeniedView()
    private let progressIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
    private let toolbar = PhotoLibraryToolbar()
    private let dimView = UIView()
    private let albumsTableView = PhotoLibraryAlbumsTableView()
    private let placeholderView = UILabel()
    
    private let dataSource = CollectionViewDataSource<PhotoLibraryItemCell>(cellReuseIdentifier: "PhotoLibraryItemCell")

    init() {

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(frame: .zero)

        dataSource.additionalCellConfiguration = { [weak self] cell, data, collectionView, indexPath in
            self?.configureCell(cell, wihData: data, inCollectionView: collectionView, atIndexPath: indexPath)
        }
        
        backgroundColor = .white
        collectionView.alpha = 0.0
        
        setUpCollectionView()
        
        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTitleViewTap(_:))))
        
        accessDeniedView.isHidden = true
        accessDeniedView.titleLabel.text = "To Select a Photo"
        accessDeniedView.messageLabel.text = "Allow CityPower to access your photo library"
        accessDeniedView.button.setTitle("Allow access to photo library", for: .normal)
        
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimView.alpha = 0
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onDimViewTap(_:))))
        
        placeholderView.isHidden = true
        placeholderView.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(22))!
        placeholderView.textColor = .black
        
        addSubview(collectionView)
        addSubview(placeholderView)
        addSubview(accessDeniedView)
        addSubview(toolbar)
        addSubview(dimView)
        addSubview(albumsTableView)
        addSubview(titleView)
        
        progressIndicator.hidesWhenStopped = true
        progressIndicator.color = UIColor(red: 162.0 / 255, green: 162.0 / 255, blue: 162.0 / 255, alpha: 1)
        
        addSubview(progressIndicator)
    
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let titleViewSize = titleView.sizeThatFits(bounds.size)
        let toolbarSize = toolbar.sizeThatFits(bounds.size)
        
        titleView.frame = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.width, height: titleViewSize.height)
        toolbar.frame = CGRect(x: bounds.origin.x, y: bounds.maxY - toolbarSize.height, width: bounds.width, height: toolbarSize.height)
        collectionView.frame = CGRect(x: bounds.origin.x, y: titleView.frame.maxY, width: bounds.width, height: toolbar.frame.minY - titleView.frame.maxY)
                
        placeholderView.frame.size = collectionView.bounds.size
        placeholderView.center = collectionView.center
        
        collectionSnapshotView?.frame = collectionView.frame
        
        layoutAlbumsTableView()
        
        dimView.frame = bounds
        
        accessDeniedView.frame = collectionView.bounds
        
        progressIndicator.center = center
    }
    
    var onDiscardButtonTap: (() -> ())? {
        get { return toolbar.onDiscardButtonTap }
        set { toolbar.onDiscardButtonTap = newValue }
    }
    
    var onConfirmButtonTap: (() -> ())? {
        get { return toolbar.onConfirmButtonTap }
        set { toolbar.onConfirmButtonTap = newValue }
    }
    
    var onAccessDeniedButtonTap: (() -> ())? {
        get { return accessDeniedView.onButtonTap }
        set { accessDeniedView.onButtonTap = newValue }
    }
    
    var onTitleTap: (() -> ())?
    var onDimViewTap: (() -> ())?
    
    func setItems(_ items: [PhotoLibraryItemCellData], scrollToBottom: Bool, completion: (() -> ())?) {
        
        if scrollToBottom {
            coverCollectionViewWithItsSnapshot()
        }
        
        dataSource.deleteAllItems()
        collectionView.reloadData()
        
        ObjCExceptionCatcher.tryClosure(
            tryClosure: { [collectionView, collectionSnapshotView, dataSource] in
                collectionView.performBatchUpdates(
                    animated: true,
                    updates: {
                        let indexPathsToInsert = (0 ..< items.count).map { IndexPath(item: $0, section: 0) }
                        collectionView.insertItems(at: indexPathsToInsert)
                        
                        dataSource.setItems(items)
                    },
                    completion: { _ in
                        if scrollToBottom {
                            collectionView.scrollToBottom()
                            collectionSnapshotView?.removeFromSuperview()
                        }
                        completion?()
                    }
                )
            },
            catchClosure: { _ in
                self.recreateCollectionView()
                completion?()
            }
        )
    }
    
    func applyChanges(_ changes: PhotoLibraryViewChanges, completion: (() -> ())?) {
        
        ObjCExceptionCatcher.tryClosure(
            tryClosure: { [collectionView, dataSource] in
                collectionView.performBatchUpdates(animated: true, updates: {
                    
                    let toIndexPath = { (index: Int) in
                        IndexPath(item: index, section: 0)
                    }

                    let indexPathsToDelete = changes.removedIndexes.map(toIndexPath)
                    
                    if indexPathsToDelete.count > 0 {
                        collectionView.deleteItems(at: indexPathsToDelete)
                        dataSource.deleteItems(at: indexPathsToDelete)
                    }
                    
                    let indexPathsToInsert = changes.insertedItems.map { toIndexPath($0.index) }
                    
                    if indexPathsToInsert.count > 0 {
                        collectionView.insertItems(at: indexPathsToInsert)
                        dataSource.insertItems(changes.insertedItems.map { item in
                            (item: item.cellData, indexPath: toIndexPath(item.index))
                        })
                    }
                    
                    let indexPathsToUpdate = changes.updatedItems.map { toIndexPath($0.index) }
                    
                    if indexPathsToUpdate.count > 0 {
                        collectionView.reloadItems(at: indexPathsToUpdate)
                        
                        changes.updatedItems.forEach { index, newCellData in
                            
                            let indexPath = toIndexPath(index)
                            let oldCellData = dataSource.item(at: indexPath)
                            
                            var newCellData = newCellData
                            newCellData.selected = oldCellData.selected
                            
                            dataSource.replaceItem(at: indexPath, with: newCellData)
                        }
                    }
                    
                    changes.movedIndexes.forEach { from, to in
                        let sourceIndexPath = toIndexPath(from)
                        let targetIndexPath = toIndexPath(to)
                        
                        collectionView.moveItem(at: sourceIndexPath, to: targetIndexPath)
                        dataSource.moveItem(at: sourceIndexPath, to: targetIndexPath)
                    }
                    
                    }, completion: { _ in
                        completion?()
                })
            },
            catchClosure: { _ in
                self.recreateCollectionView()
                completion?()
            }
        )
    }
    
    func deselectAndAdjustAllCells() {
        
        guard let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems
            else { return }
        
        for indexPath in indexPathsForSelectedItems {
            collectionView.deselectItem(at: indexPath, animated: false)
            onDeselectItem(at: indexPath)
        }
    }
    
    func scrollToBottom() {
        collectionView.scrollToBottom()
    }
    
    func setTitle(_ title: String) {
        titleView.setTitle(title)
    }
    
    func setTitleVisible(_ visible: Bool) {
        titleView.setTitleVisible(visible)
        titleView.isUserInteractionEnabled = visible
    }
    
    func setPlaceholderTitle(_ title: String) {
        placeholderView.text = title
    }
    
    func setPlaceholderVisible(_ visible: Bool) {
        placeholderView.isHidden = !visible
    }
    
    func setAccessDeniedViewVisible(_ visible: Bool) {
        accessDeniedView.isHidden = !visible
    }

    func setProgressVisible(_ visible: Bool) {
        if visible {
            progressIndicator.startAnimating()
        } else {
            progressIndicator.stopAnimating()
            
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.collectionView.alpha = 1.0
            }
        }
    }
    
    func setAlbums(_ albums: [PhotoLibraryAlbumCellData]) {
        albumsTableView.setCellDataList(albums) { [weak self] in
            self?.setNeedsLayout()
        }
    }
    
    func selectAlbum(withId id: String) {
        albumsTableView.selectAlbum(withId: id)
    }
    
    func showAlbumsList() {
        UIView.animate(withDuration: 0.25) {
            self.albumsListState = .expanded
            self.dimView.alpha = 1
            self.layoutAlbumsTableView()
            self.titleView.rotateIconUp()
        }
    }
    
    func hideAlbumsList() {
        UIView.animate(withDuration: 0.25) {
            self.albumsListState = .collapsed
            self.dimView.alpha = 0
            self.layoutAlbumsTableView()
            self.titleView.rotateIconDown()
        }
    }
    
    func toggleAlbumsList() {
        switch albumsListState {
        case .collapsed:
            showAlbumsList()
        case .expanded:
            hideAlbumsList()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        adjustDimmingForCell(cell)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let cellData = dataSource.item(at: indexPath)
        
        cellData.onSelectionPrepare?()
        
        return canSelectMoreItems && cellData.previewAvailable
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        dataSource.mutateItem(at: indexPath) { (cellData: inout PhotoLibraryItemCellData) in
            cellData.selected = true
        }
        dataSource.item(at: indexPath).onSelect?()
        
        adjustDimmingForCellAtIndexPath(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        onDeselectItem(at: indexPath)
    }
    
    private func setUpCollectionView() {
        collectionView.backgroundColor = .white
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        collectionView.alwaysBounceVertical = true
        collectionView.register(
            PhotoLibraryItemCell.self,
            forCellWithReuseIdentifier: dataSource.cellReuseIdentifier
        )
    }
    
    private func recreateCollectionView() {
        
        let oldBounds = collectionView.bounds
        let collectionViewSnapshot = collectionView.snapshotView(afterScreenUpdates: false)
        
        collectionViewSnapshot?.frame = collectionView.frame
        
        collectionView.removeFromSuperview()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        setUpCollectionView()
        addSubview(collectionView)
        
        if let snapshot = collectionViewSnapshot {
            collectionView.superview?.addSubview(snapshot)
        }
        
        collectionView.reloadData()
        
        OperationQueue.main.addOperation {
            self.collectionView.scrollRectToVisible(oldBounds, animated: false)
            
            UIView.animate(
                withDuration: 0.2,
                animations: {
                    collectionViewSnapshot?.alpha = 0
                }, completion: { _ in
                    collectionViewSnapshot?.removeFromSuperview()
                }
            )
        }
    }
    
    private func adjustDimmingForCell(_ cell: UICollectionViewCell) {
        let shouldDimCell = (dimsUnselectedItems && !cell.isSelected)
        cell.contentView.alpha = shouldDimCell ? 0.3 : 1
    }
    
    private func adjustDimmingForCellAtIndexPath(_ indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            adjustDimmingForCell(cell)
        }
    }
    
    private func adjustDimmingForVisibleCells() {
        collectionView.visibleCells.forEach { adjustDimmingForCell($0) }
    }
    
    private func configureCell(_ cell: PhotoLibraryItemCell, wihData data: PhotoLibraryItemCellData,
        inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        
        cell.onImageSetFromSource = { [weak self] in
            self?.dataSource.mutateItem(data, at: indexPath) { (data: inout PhotoLibraryItemCellData) in
                data.previewAvailable = true
            }
        }

        if data.selected {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
    }
    
    private func onDeselectItem(at indexPath: IndexPath) {
        dataSource.mutateItem(at: indexPath) { (cellData: inout PhotoLibraryItemCellData) in
            cellData.selected = false
        }
        dataSource.item(at: indexPath).onDeselect?()
        
        adjustDimmingForCellAtIndexPath(indexPath)
    }
    
    @objc private func onTitleViewTap(_: UITapGestureRecognizer) {
        onTitleTap?()
    }
    
    @objc private func onDimViewTap(_: UITapGestureRecognizer) {
        onDimViewTap?()
    }
    
    private func coverCollectionViewWithItsSnapshot() {
        collectionSnapshotView = collectionView.snapshotView(afterScreenUpdates: false)
        collectionSnapshotView?.backgroundColor = collectionView.backgroundColor
        
        if let collectionSnapshotView = collectionSnapshotView {
            insertSubview(collectionSnapshotView, aboveSubview: collectionView)
        }
    }
    
    private func layoutAlbumsTableView() {
        
        let size = albumsTableView.sizeThatFits(CGSize(
            width: bounds.width,
            height: bounds.height - titleView.bounds.height
        ))
        
        let top: CGFloat
        
        switch albumsListState {
        case .collapsed:
            top = titleView.bounds.maxY - size.height
        case .expanded:
            top = titleView.bounds.maxY
        }
        
        albumsTableView.frame = CGRect(
            x: bounds.minX,
            y: top,
            width: bounds.width,
            height: size.height
        )
    }
}


final class PhotoLibraryLayout: UICollectionViewFlowLayout {
    
    private var attributes = [IndexPath: UICollectionViewLayoutAttributes]()
    private var contentSize: CGSize = .zero
    
    private let insets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
    private let cellSpacing = CGFloat(6)
    private let numberOfPhotosInRow = 3
        
    func cellSize() -> CGSize {
    
        if let collectionView = collectionView {
            let contentWidth = collectionView.bounds.size.width - insets.left - insets.right
            let itemWidth = (contentWidth - CGFloat(numberOfPhotosInRow - 1) * cellSpacing) / CGFloat(numberOfPhotosInRow)
            return CGSize(width: itemWidth, height: itemWidth)
        } else {
            return .zero
        }
    }
    
    override var collectionViewContentSize: CGSize {
        return contentSize
    }
    
    override func prepare() {
        
        guard let collectionView = collectionView else {
            contentSize = .zero
            attributes = [:]
            return
        }
        
        attributes.removeAll()
        
        let itemSize = cellSize()
        
        let section = 0
        let numberOfItems = collectionView.numberOfItems(inSection: section)
        
        var maxY = CGFloat(0)
        
        for item in 0 ..< numberOfItems {
            
            let row = floor(CGFloat(item) / CGFloat(numberOfPhotosInRow))
            let column = CGFloat(item % numberOfPhotosInRow)
            
            let origin = CGPoint(
                x: insets.left + column * (itemSize.width + cellSpacing),
                y: insets.top + row * (itemSize.height + cellSpacing)
            )
            
            let indexPath = IndexPath(item: item, section: section)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(origin: origin, size: itemSize)
            
            maxY = max(maxY, attributes.frame.maxY)
            
            self.attributes[indexPath] = attributes
        }
        
        contentSize = CGSize(width: collectionView.frame.maxX, height: maxY)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributes.filter { $1.frame.intersects(rect) }.map { $1 }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return attributes[indexPath]
    }
}


final class PhotoLibraryTitleView: UIView {
    
    private let label = UILabel()
    private let iconView = UIImageView()
    private let labelToIconSpacing: CGFloat = 10
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        label.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(24))!
        iconView.image = UIImage(named: "arrow-down")
        
        addSubview(label)
        addSubview(iconView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTitle(_ title: String) {
        label.text = title
        setNeedsLayout()
    }
    
    func setTitleVisible(_ visible: Bool) {
        label.isHidden = !visible
        iconView.isHidden = !visible
    }
    
    func rotateIconUp() {
        iconView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi)
    }
    
    func rotateIconDown() {
        iconView.transform = CGAffineTransform(rotationAngle: 0.001)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: 80 + safeAreaInsets.top)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let iconSize = iconView.image?.size ?? .zero
        let topInset = safeAreaInsets.top / 2
        
        label.sizeToFit()
        label.frame.origin.x = (bounds.width - (label.frame.width + labelToIconSpacing + iconSize.width)) / 2
        label.frame.origin.y = bounds.origin.y + topInset + label.frame.height / 2
        
        iconView.frame = CGRect(origin: .zero, size: iconSize)
        iconView.center = CGPoint(
            x: ceil(label.frame.maxX + labelToIconSpacing) + iconSize.width / 2,
            y: bounds.midY + topInset
        )
    }
}


final class PhotoLibraryAlbumsTableView: UIView, UITableViewDataSource, UITableViewDelegate {
    
    private let topSeparator = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private var cellDataList = [PhotoLibraryAlbumCellData]()
    private var selectedAlbumId: String?
    
    private let cellId = "AlbumCell"
    private var cellLabelFont: UIFont?
    private var cellBackgroundColor: UIColor?
    private var cellDefaultLabelColor: UIColor?
    private var cellSelectedLabelColor: UIColor?
    
    private let separatorHeight: CGFloat = 1
    private let minInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        topSeparator.backgroundColor = .clear
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = 60
        tableView.alwaysBounceVertical = false
        tableView.register(PhotoLibraryAlbumsTableViewCell.self, forCellReuseIdentifier: cellId)
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.backgroundColor = .white
        
        addSubview(tableView)
        addSubview(topSeparator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCellDataList(_ cellDataList: [PhotoLibraryAlbumCellData], completion: @escaping () -> ()) {
        self.cellDataList = cellDataList
        tableView.reloadData()
        
        DispatchQueue.main.async(execute: completion)
    }
    
    func selectAlbum(withId id: String) {
        
        let indexPathsToReload = [selectedAlbumId, id].compactMap { albumId in
            cellDataList.firstIndex(where: { $0.identifier == albumId }).flatMap { IndexPath(row: $0, section: 0) }
        }
        selectedAlbumId = id
        tableView.reloadRows(at: indexPathsToReload, with: .fade)
    }
            
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellDataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? PhotoLibraryAlbumsTableViewCell else { return UITableViewCell() }
        
        let cellData = cellDataList[indexPath.row]
        
        cell.setCellData(cellData)
        cell.isSelected = (cellData.identifier == selectedAlbumId)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellData = cellDataList[indexPath.row]
        cellData.onSelect()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        
        let tableViewSize = tableView.sizeThatFits(size)
        let tableVerticalInsets = minInsets.top + minInsets.bottom
        return CGSize(
            width: tableViewSize.width,
            height: min(size.height, tableViewSize.height + separatorHeight + tableVerticalInsets)
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        topSeparator.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.maxX - bounds.minX, height: separatorHeight)
        tableView.frame = CGRect(x: bounds.minX, y: topSeparator.bounds.maxY, width: topSeparator.bounds.width, height: bounds.maxY - topSeparator.bounds.maxY)
        tableView.contentInset = UIEdgeInsets(top: minInsets.top, left: minInsets.left, bottom: max(minInsets.bottom, safeAreaInsets.bottom), right: minInsets.right)
    }
}


final class PhotoLibraryAlbumsTableViewCell: UITableViewCell {
    
    private let insets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    private let imageSize = CGSize(width: 44, height: 44)
    private let imageToTitleSpacing: CGFloat = 16
    private let label = UILabel()
    private let coverImageView = UIImageView()
    
    private var coverImage: ImageSource? {
        didSet {
            updateImage()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            label.textColor = isSelected ? .blueCity : .black
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        selectedBackgroundView = UIView()
        backgroundColor = .white
        
        label.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(22))!
        
        coverImageView.backgroundColor = .lightGray
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.layer.cornerRadius = 6
        coverImageView.layer.masksToBounds = true
        coverImageView.layer.shouldRasterize = true
        coverImageView.layer.rasterizationScale = UIScreen.main.nativeScale
        
        contentView.addSubview(coverImageView)
        contentView.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCellData(_ cellData: PhotoLibraryAlbumCellData) {
        label.text = cellData.title
        coverImage = cellData.coverImage
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        coverImageView.frame = CGRect(
            x: contentView.bounds.origin.x + insets.left,
            y: contentView.bounds.origin.y + floor((bounds.height - imageSize.height) / 2),
            width: imageSize.width,
            height: imageSize.height
        )
        
        updateImage()
        
        let labelLeft = coverImageView.frame.maxX + imageToTitleSpacing
        let labelMaxWidth = (bounds.maxX - insets.right) - labelLeft
        
        label.frame.size = CGSize(width: labelMaxWidth, height: bounds.height)
        label.frame.origin.x = labelLeft
        label.center.y = bounds.midY
    }
    
    private func updateImage() {
        coverImageView.setImage(fromSource: coverImage)
    }
}

struct PhotoLibraryAlbumCellData {
    let identifier: String
    let title: String
    let coverImage: ImageSource?
    let onSelect: () -> ()
}


final class PhotoLibraryItemCell: PhotoCollectionViewCell, Customizable {
    
    private let cloudIconView = UIImageView()
    private var getSelectionIndex: (() -> Int?)?
    private let selectionIndexBadgeContainer = UIView()
    
    private let selectionIndexBadge: UILabel = {
        let label = UILabel()
        label.backgroundColor = .lightBlueCity
        label.textColor = .white
        label.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(16))!
        label.frame.size = CGSize(width: 24, height: 24)
        label.textAlignment = .center
        label.layer.cornerRadius = 11
        label.layer.masksToBounds = true
        
        return label
    }()
    
    var isRedesign = false
        
    override var isSelected: Bool {
        didSet {
            if isRedesign {
                layer.borderWidth = 0
            }
        }
    }
    
    func adjustAppearanceForSelected(_ isSelected: Bool, animated: Bool) {
        
        func adjustAppearance() {
            if isSelected {
                self.imageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.selectionIndexBadgeContainer.transform = self.imageView.transform
                self.selectionIndexBadgeContainer.alpha = 1
            } else {
                self.imageView.transform = .identity
                self.selectionIndexBadgeContainer.transform = self.imageView.transform
                self.selectionIndexBadgeContainer.alpha = 0
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: adjustAppearance)
        } else {
            adjustAppearance()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        getSelectionIndex = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let backgroundView = UIView()
        let onePixel = 1.0 / UIScreen.main.nativeScale
        
        selectedBorderThickness = 5
        
        imageView.isAccessibilityElement = true
        imageViewInsets = UIEdgeInsets(top: onePixel, left: onePixel, bottom: onePixel, right: onePixel)
        
        setUpRoundedCorners(for: self)
        setUpRoundedCorners(for: backgroundView)
        setUpRoundedCorners(for: imageView)
        setUpRoundedCorners(for: selectionIndexBadgeContainer)
        
        selectionIndexBadgeContainer.alpha = 0
        selectionIndexBadgeContainer.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        selectionIndexBadgeContainer.addSubview(selectionIndexBadge)
        
        contentView.insertSubview(cloudIconView, at: 0)
        contentView.addSubview(selectionIndexBadgeContainer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let onePixel = CGFloat(1) / UIScreen.main.nativeScale
        let backgroundInsets = UIEdgeInsets(top: onePixel, left: onePixel, bottom: onePixel, right: onePixel)
        
        backgroundView?.frame = imageView.frame.inset(by: backgroundInsets)
        
        cloudIconView.sizeToFit()
        cloudIconView.frame.origin = CGPoint(x: contentView.bounds.maxX - cloudIconView.bounds.width, y: contentView.bounds.maxY - cloudIconView.bounds.height)
        
        selectionIndexBadgeContainer.center = imageView.center
        selectionIndexBadgeContainer.bounds = imageView.bounds
        
        selectionIndexBadge.center = CGPoint(x: 18, y: 18)
    }
    
    override func didRequestImage(requestId imageRequestId: ImageRequestId) {
        self.imageRequestId = imageRequestId
    }
    
    override func imageRequestResultReceived(_ result: ImageRequestResult<UIImage>) {
        if result.requestId == self.imageRequestId {
            onImageSetFromSource?()
        }
    }
    
    func setCloudIcon(_ icon: UIImage?) {
        cloudIconView.image = icon
        setNeedsLayout()
    }
        
    func setSelectionIndex(_ selectionIndex: Int?) {
        selectionIndexBadge.text = selectionIndex.flatMap { String($0) }
    }
    
    var onImageSetFromSource: (() -> ())?
    
    func customizeWithItem(_ item: PhotoLibraryItemCellData) {
        imageSource = item.image
        getSelectionIndex = item.getSelectionIndex
    }
    
    private var imageRequestId: ImageRequestId?
    
    private func setUpRoundedCorners(for view: UIView) {
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = UIScreen.main.nativeScale
    }
}


struct PhotoLibraryItemCellData: Equatable {
    
    var image: ImageSource
    var selected = false
    var previewAvailable = false
    
    var onSelect: (() -> ())?
    var onSelectionPrepare: (() -> ())?
    var onDeselect: (() -> ())?
    var getSelectionIndex: (() -> Int?)?
    
    init(image: ImageSource, getSelectionIndex: (() -> Int?)? = nil) {
        self.image = image
        self.getSelectionIndex = getSelectionIndex
    }
    
    static func ==(cellData1: PhotoLibraryItemCellData, cellData2: PhotoLibraryItemCellData) -> Bool {
        return cellData1.image == cellData2.image
    }
}


final class PhotoLibraryToolbar: UIView {
    
    private let discardButton = UIButton()
    private let confirmButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        discardButton.addTarget(self, action: #selector(onDiscardButtonTap(_:)), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(onConfirmButtonTap(_:)), for: .touchUpInside)
       
        discardButton.setImage(UIImage(named: "bounds"), for: .normal)
        confirmButton.setImage(UIImage(named: "check"), for: .normal)
        
        addSubview(discardButton)
        addSubview(confirmButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var onDiscardButtonTap: (() -> ())?
    var onConfirmButtonTap: (() -> ())?
        
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: 60 + safeAreaInsets.bottom)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let bottomInset = safeAreaInsets.bottom / 2
        
        discardButton.bounds.size = CGSize(width: 44, height: 44)
        discardButton.center = CGPoint(
            x: bounds.origin.x + bounds.width / 4,
            y: bounds.origin.y + bounds.height / 2 - bottomInset
        )
        
        confirmButton.bounds.size = CGSize(width: 44, height: 44)
        confirmButton.center = CGPoint(
            x: bounds.maxX - bounds.width / 4,
            y: bounds.origin.y + bounds.height / 2 - bottomInset
        )
    }
    
    // MARK: - Private
    @objc private func onDiscardButtonTap(_: UIButton) {
        onDiscardButtonTap?()
    }
    
    @objc private func onConfirmButtonTap(_: UIButton) {
        onConfirmButtonTap?()
    }
}

