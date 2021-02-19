//
//  LocationProvider.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import CoreLocation

public protocol LocationProvider: class {
    func location(completion: @escaping ((CLLocation?) -> ()))
}

public class LocationProviderImpl: NSObject, LocationProvider, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    private var completions = [((CLLocation?) -> ())]()
    
    public override init() {
        super.init()
        locationManager.delegate = self
    }
    
    public func location(completion: @escaping ((CLLocation?) -> ())) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            getLocationWhenAuthorized(completion: completion)
        case .notDetermined, .denied, .restricted:
            completion(nil)
        @unknown default:
            assertionFailure("Unknown authorization status")
            completion(nil)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        performCompletions(location: location)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        performCompletions(location: nil)
    }

    
    private func getLocationWhenAuthorized(completion: @escaping ((CLLocation?) -> ())) {
        if let location = locationManager.location {
            completion(location)
            return
        }

        completions.append(completion)
        locationManager.requestLocation()
    }
    
    private func performCompletions(location: CLLocation?) {
        completions.forEach { $0(location) }
        completions = []
    }
}
