//
//  ExpandButton.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


protocol ButtonPanelDelegate: NSObject {
  
    func didTapButtonWithLoc(_ center: CGPoint)
    func didTapDeleteWithLoc(_ center: CGPoint)
    func didTapEditWithLoc(_ center: CGPoint)
    func didCollapse(_ willCollapse: Bool)
}

fileprivate let buttonSize: CGFloat = 60
fileprivate let shadowOpacity: Float = 0.7

class ButtonPanelView: UIView {
    
    weak var delegate: ButtonPanelDelegate?
    
    lazy var selectorView: UIView = {
        let selectorView = UIView(frame: CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
        selectorView.backgroundColor = .blueCity
        return selectorView
    }()
        
    lazy var menuButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle("➕", for: .normal)
        button.backgroundColor = .clear
        button.layer.cornerRadius = buttonSize / 2
        button.addTarget(
          self, action: #selector(handleTogglePanelButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var editButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UIImage(named: "edit"), for: .normal)
        button.layer.cornerRadius = buttonSize / 2
        button.isHidden = true
        button.addTarget(
          self, action: #selector(handleEditButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var addButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .black
        button.layer.cornerRadius = buttonSize / 2
        button.isHidden = true
        button.addTarget(
          self, action: #selector(handleExpandedButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    lazy var deleteButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UIImage(named: "delete"), for: .normal)
        button.layer.cornerRadius = buttonSize / 2
        button.isHidden = true
        button.addTarget(
          self, action: #selector(handleDeleteButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var expandedStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.isHidden = true
        stackView.addArrangedSubview(addButton)
        stackView.addArrangedSubview(editButton)
        stackView.addArrangedSubview(deleteButton)
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

        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        containerStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

        translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalTo: containerStackView.widthAnchor).isActive = true
        self.heightAnchor.constraint(equalTo: containerStackView.heightAnchor).isActive = true
    }
}


extension ButtonPanelView {
    
    @objc private func handleTogglePanelButtonTapped(_ sender: UIButton) {
        let willExpand = expandedStackView.isHidden
        let menuButtonNewTitle = willExpand ? "✖️" : "➕"
        delegate?.didCollapse(willExpand)
        
        UIView.animate(
            withDuration: 0.3, delay: 0, options: .curveEaseIn,
            animations: {
                self.selectorView.alpha = willExpand ? 1.0 : 0.0
                self.selectorView.frame.origin = willExpand ? CGPoint(x: 180, y: 0) : CGPoint(x: 0, y: 0)
                self.expandedStackView.subviews.forEach { $0.isHidden = !$0.isHidden }
                self.expandedStackView.isHidden = !self.expandedStackView.isHidden
                if willExpand {
                    self.menuButton.setTitle(menuButtonNewTitle, for: .normal)
                }
            }, completion: { _ in
                if !willExpand {
                    self.menuButton.setTitle(menuButtonNewTitle, for: .normal)
                }
        })
    }
    
    @objc private func handleExpandedButtonTapped(_ sender: UIButton) {
        
        UIView.animate(withDuration: 0.3) {
            self.selectorView.frame.origin.x = sender.frame.origin.x
        }
        
        delegate?.didTapButtonWithLoc(sender.center)
    }
    @objc private func handleDeleteButtonTapped(_ sender: UIButton) {
        
        UIView.animate(withDuration: 0.3) {
            self.selectorView.frame.origin.x = sender.frame.origin.x
        }
        delegate?.didTapDeleteWithLoc(sender.center)
    }
    @objc private func handleEditButtonTapped(_ sender: UIButton) {
        
        UIView.animate(withDuration: 0.3) {
            self.selectorView.frame.origin.x = sender.frame.origin.x
        }
        delegate?.didTapEditWithLoc(sender.center)
    }
}   
