//
//  BaseUiKitRouter.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation

class BaseUIKitRouter {
    
    private weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func focusOnCurrentModule(shouldDismissAnimated: (_ dismissedViewController: UIViewController) -> Bool) {
        guard let viewController = viewController else { return }
        
        if let navigationController = viewController.navigationController,
            viewController != navigationController.topViewController
        {
            let animated = navigationController.topViewController.flatMap { shouldDismissAnimated($0) } ?? true
            navigationController.popToViewController(viewController, animated: animated)
        }
        
        if let presentedViewController = viewController.presentedViewController {
            viewController.dismiss(animated: shouldDismissAnimated(presentedViewController), completion: nil)
        }
    }
    
    func focusOnCurrentModule() {
        focusOnCurrentModule(shouldDismissAnimated: { _ in true })
    }
    
    func dismissCurrentModule(animated: Bool) {
        guard let viewController = viewController else { return }
        
        if let navigationController = viewController.navigationController {
            if let index = navigationController.viewControllers.firstIndex(of: viewController), index > 0 {
                let previousController = navigationController.viewControllers[index - 1]
                navigationController.popToViewController(previousController, animated: animated)
            } else {
                navigationController.presentingViewController?.dismiss(animated: animated, completion: nil)
            }
        } else {
            viewController.presentingViewController?.dismiss(animated: animated, completion: nil)
        }
    }
    
    func dismissCurrentModule() {
        dismissCurrentModule(animated: true)
    }
    
    func push(_ viewController: UIViewController, animated: Bool) {
        self.viewController?.navigationController?.pushViewController(viewController, animated: animated)
    }
    
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> ())? = nil) {
        if let topViewController = (self.viewController as? UINavigationController)?.topViewController {
            topViewController.present(viewController, animated: animated, completion: completion)
        } else {
            self.viewController?.present(viewController, animated: animated, completion: completion)
        }
    }
}


public class BasePhotoEditorAssembly {

    let serviceFactory: ServiceFactory
    
    init(serviceFactory: ServiceFactory) {
        self.serviceFactory = serviceFactory
    }
}
