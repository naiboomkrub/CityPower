//
//  FilterButton.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 11/3/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation

protocol FilterPanelDelegate: NSObject {
  
    func didTapButton(_ center: CGPoint)
    func didTapDelete(_ center: CGPoint)
    func didTapEdit(_ center: CGPoint)
    func didTapAll(_ center: CGPoint)
    func didCollapseFilter(_ willCollapse: Bool)
}

fileprivate let buttonSize: CGFloat = 60
fileprivate let shadowOpacity: Float = 0.7

class FilterPanelView: UIView {
    
    weak var delegate: FilterPanelDelegate?
    
    let largeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
    
    var currentButton: CGPoint?
    
    lazy var selectorView: UIView = {
        let selectorView = UIView(frame: CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
        selectorView.backgroundColor = .blueCity
        return selectorView
    }()
        
    lazy var menuButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UIImage(systemName: "magnifyingglass",  withConfiguration: self.largeConfig), for: .normal)
        button.tintColor = .black
        button.backgroundColor = .clear
        button.layer.cornerRadius = buttonSize / 2
        button.addTarget(
          self, action: #selector(handleTogglePanelButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var editButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UIImage(systemName: "arrow.clockwise",  withConfiguration: largeConfig), for: .normal)
        button.tintColor = .Gray1
        button.layer.cornerRadius = buttonSize / 2
        button.isHidden = true
        button.addTarget(
          self, action: #selector(handleEditButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var addButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UIImage(systemName: "checkmark", withConfiguration: largeConfig), for: .normal)
        button.tintColor = .green
        button.layer.cornerRadius = buttonSize / 2
        button.isHidden = true
        button.addTarget(
          self, action: #selector(handleExpandedButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    lazy var deleteButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UIImage(systemName: "xmark",  withConfiguration: largeConfig), for: .normal)
        button.tintColor = .red
        button.layer.cornerRadius = buttonSize / 2
        button.isHidden = true
        button.addTarget(
          self, action: #selector(handleDeleteButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var allButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UIImage(systemName: "restart.circle",  withConfiguration: largeConfig), for: .normal)
        button.tintColor = .black
        button.layer.cornerRadius = buttonSize / 2
        button.isHidden = true
        button.addTarget(
          self, action: #selector(handleAllButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var expandedStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.isHidden = true
        stackView.addArrangedSubview(addButton)
        stackView.addArrangedSubview(editButton)
        stackView.addArrangedSubview(deleteButton)
        stackView.addArrangedSubview(allButton)
        return stackView
    }()

    lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.addArrangedSubview(expandedStackView)
        stackView.addArrangedSubview(menuButton)
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .lightBlueCity

        layer.cornerRadius = buttonSize / 2
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = .zero
        
        selectorView.alpha = 0.0
        selectorView.layer.cornerRadius = buttonSize / 2
        
        addSubview(selectorView)
        addSubview(containerStackView)
        setConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setConstraints() {
        
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        menuButton.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
        
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        editButton.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true

        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true

        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        deleteButton.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
        
        allButton.translatesAutoresizingMaskIntoConstraints = false
        allButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        allButton.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true

        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        containerStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

        translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalTo: containerStackView.widthAnchor).isActive = true
        self.heightAnchor.constraint(equalTo: containerStackView.heightAnchor).isActive = true
    }
}


extension FilterPanelView {
    
    @objc private func handleTogglePanelButtonTapped(_ sender: UIButton) {
        let willExpand = expandedStackView.isHidden
        delegate?.didCollapseFilter(willExpand)
        
        UIView.animate(
            withDuration: 0.3, delay: 0, options: .curveEaseIn,
            animations: {
                self.selectorView.alpha = willExpand ? 1.0 : 0.0
                
                if let button = self.currentButton {
                    self.selectorView.frame.origin = willExpand ? button : CGPoint(x: 0, y: 0)
                } else {
                    self.selectorView.frame.origin = willExpand ? CGPoint(x: 180, y: 0) : CGPoint(x: 0, y: 0)
                }
                self.expandedStackView.subviews.forEach { $0.isHidden = !$0.isHidden }
                self.expandedStackView.isHidden = !self.expandedStackView.isHidden
                if willExpand {
                    self.menuButton.setImage(UIImage(systemName: "xmark",  withConfiguration: self.largeConfig), for: .normal)
                }
            }, completion: { _ in
                if !willExpand {
                    self.menuButton.setImage(UIImage(systemName: "magnifyingglass",  withConfiguration: self.largeConfig), for: .normal)
                }
        })
    }
    
    @objc private func handleExpandedButtonTapped(_ sender: UIButton) {
        
        UIView.animate(withDuration: 0.3) {
            self.selectorView.frame.origin.x = sender.frame.origin.x
        }
        currentButton = sender.frame.origin
        delegate?.didTapButton(sender.frame.origin)
    }
    @objc private func handleDeleteButtonTapped(_ sender: UIButton) {
        
        UIView.animate(withDuration: 0.3) {
            self.selectorView.frame.origin.x = sender.frame.origin.x
        }
        currentButton = sender.frame.origin
        delegate?.didTapDelete(sender.frame.origin)
    }
    
    @objc private func handleAllButtonTapped(_ sender: UIButton) {
        
        UIView.animate(withDuration: 0.3) {
            self.selectorView.frame.origin.x = sender.frame.origin.x
        }
        currentButton = sender.frame.origin
        delegate?.didTapAll(sender.frame.origin)
    }
    
    @objc private func handleEditButtonTapped(_ sender: UIButton) {
        
        UIView.animate(withDuration: 0.3) {
            self.selectorView.frame.origin.x = sender.frame.origin.x
        }
        currentButton = sender.frame.origin
        delegate?.didTapEdit(sender.frame.origin)
    }
}
