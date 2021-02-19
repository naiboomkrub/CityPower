//
//  PhotoLibraryViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit


final class PhotoLibraryViewController: PhotoEditorViewController, PhotoLibraryViewInput {
    
    private let photoLibraryView = PhotoLibraryView()

    override func loadView() {
        view = photoLibraryView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onViewDidLoad?()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    var onItemSelect: ((PhotoLibraryItem) -> ())?
    var onViewDidLoad: (() -> ())?
    
    var onTitleTap: (() -> ())? {
        get { return photoLibraryView.onTitleTap }
        set { photoLibraryView.onTitleTap = newValue }
    }
    
    var onPickButtonTap: (() -> ())? {
        get { return photoLibraryView.onConfirmButtonTap }
        set { photoLibraryView.onConfirmButtonTap = newValue }
    }
    
    var onCancelButtonTap: (() -> ())? {
        get { return photoLibraryView.onDiscardButtonTap }
        set { photoLibraryView.onDiscardButtonTap = newValue }
    }
    
    var onAccessDeniedButtonTap: (() -> ())? {
        get { return photoLibraryView.onAccessDeniedButtonTap }
        set { photoLibraryView.onAccessDeniedButtonTap = newValue }
    }
    
    var onDimViewTap: (() -> ())? {
        get { return photoLibraryView.onDimViewTap }
        set { photoLibraryView.onDimViewTap = newValue }
    }
    
    func setTitleVisible(_ visible: Bool) {
        photoLibraryView.setTitleVisible(visible)
    }
    
    func setPlaceholderState(_ state: PhotoLibraryPlaceholderState) {
        switch state {
        case .hidden:
            photoLibraryView.setPlaceholderVisible(false)
        case .visible(let title):
            photoLibraryView.setPlaceholderTitle(title)
            photoLibraryView.setPlaceholderVisible(true)
        }
    }
    
    @nonobjc func setTitle(_ title: String) {
        photoLibraryView.setTitle(title)
    }
    
    func setItems(_ items: [PhotoLibraryItemCellData], scrollToBottom: Bool, completion: (() -> ())?) {
        photoLibraryView.setItems(items, scrollToBottom: scrollToBottom, completion: completion)
    }
    
    func applyChanges(_ changes: PhotoLibraryViewChanges, completion: (() -> ())?) {
        photoLibraryView.applyChanges(changes, completion: completion)
    }
    
    func setCanSelectMoreItems(_ canSelectMoreItems: Bool) {
        photoLibraryView.canSelectMoreItems = canSelectMoreItems
    }
    
    func setDimsUnselectedItems(_ dimUnselectedItems: Bool) {
        photoLibraryView.dimsUnselectedItems = dimUnselectedItems
    }
    
    func deselectAllItems() {
        photoLibraryView.deselectAndAdjustAllCells()
    }
    
    func scrollToBottom() {
        photoLibraryView.scrollToBottom()
    }
    
    func setAccessDeniedViewVisible(_ visible: Bool) {
        photoLibraryView.setAccessDeniedViewVisible(visible)
    }
    
    func setProgressVisible(_ visible: Bool) {
        photoLibraryView.setProgressVisible(visible)
    }
    
    func setAlbums(_ albums: [PhotoLibraryAlbumCellData]) {
        photoLibraryView.setAlbums(albums)
    }
    
    func selectAlbum(withId id: String) {
        photoLibraryView.selectAlbum(withId: id)
    }
    
    func showAlbumsList() {
        photoLibraryView.showAlbumsList()
    }
    
    func hideAlbumsList() {
        photoLibraryView.hideAlbumsList()
    }
    
    func toggleAlbumsList() {
        photoLibraryView.toggleAlbumsList()
    }
    
    
    @objc private func onCancelButtonTap(_ sender: UIBarButtonItem) {
        onCancelButtonTap?()
    }
    
    @objc private func onPickButtonTap(_ sender: UIBarButtonItem) {
        onPickButtonTap?()
    }
}
