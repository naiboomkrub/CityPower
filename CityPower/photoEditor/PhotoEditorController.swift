//
//  PhotoEditorController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit


class PhotoEditorViewController: UIViewController, DisposeBags, DisposeBagHolder {

    public let disposeBag: DisposeBags = DisposeBagImpl()

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol DisposeBags {
    func addDisposable(_: AnyObject)
}

protocol DisposeBagHolder {
    var disposeBag: DisposeBags { get }
}

extension DisposeBags where Self: DisposeBagHolder {
    func addDisposable(_ anyObject: AnyObject) {
        disposeBag.addDisposable(anyObject)
    }
}


final class DisposeBagImpl: DisposeBags {
  
    private var disposables: [AnyObject] = []
    
    init() {}
    
    func addDisposable(_ anyObject: AnyObject) {
        disposables.append(anyObject)
    }
}
