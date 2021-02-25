//
//  SiteGroup.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 23/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxDataSources

struct SiteGroup: Codable {
    let name : String
    let image: String
        
    var dictionary: [String: Any] {
      return [
        "name": name,
        "image": image,
      ]
    }
    
    init(name: String, image: String) {
        self.name = name
        self.image = image
    }
    
    init?(dictionary: [String : Any]) {
        guard let name = dictionary["name"] as? String,
            let image = dictionary["image"] as? String else { return nil }
        
        self.name = name
        self.image = image
    }
}

extension SiteGroup: Hashable {
    static func == (lhs: SiteGroup, rhs: SiteGroup) -> Bool {
        return lhs.name == rhs.name &&
            lhs.image == rhs.image
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(image)
    }
}

extension SiteGroup: IdentifiableType {
    var identity: String {
        return self.name + self.image
    }
    
    typealias Identity = String
}
