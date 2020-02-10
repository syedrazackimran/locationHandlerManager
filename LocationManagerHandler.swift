//
//  LocationManager.swift
//  LocationManagerHandler
//
//  Created by Imran on 03/01/20.
//  Copyright © 2020 Imran. All rights reserved.
//


enum LocationResult<T> {
    case success(T)
    case failure(Error)
}


import Foundation
import CoreLocation

final class LocationManagerHandler: NSObject {
    
    private let locationManager: CLLocationManager?
    public var newLocation: ((LocationResult<CLLocation>) -> Void)?
    public var didChangeStatus:((Bool) -> Void)?
    
    init(manager: CLLocationManager = .init()) {
        self.locationManager = manager
        super.init()
        manager.delegate = self
    }
    
   public var authorizationStatus: CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    public func requestLocationAuthorization() {
        locationManager?.requestWhenInUseAuthorization()
    }
    public func getLocation() {
        locationManager?.requestLocation()
    }
    
    private func getAddress(location: CLLocation?, completionHandler:@escaping(String) -> ()) {
        let geoCoder = CLGeocoder()
        if let location = location,
            geoCoder.isGeocoding == false {
            geoCoder.reverseGeocodeLocation(location) { placeMarks, error in
                guard let error = error else {
                    geoCoder.cancelGeocode()
                    return }
                print(error.localizedDescription)
                
                if let placemarker = placeMarks?.first {
                    print(placemarker.customAddress)
                }
            }
        }
    }
}


extension LocationManagerHandler: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.sorted(by: { $0.timestamp > $1.timestamp }).first {
            newLocation?(.success(location))
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        newLocation?(.failure(error))
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined, .denied, .restricted:
            didChangeStatus?(false)
        default:
            didChangeStatus?(true)
        }
    }
}

//MARK:- CLPlacemark
extension CLPlacemark {

    var customAddress: String {
        get {
            return [[subThoroughfare, thoroughfare],
                    [subAdministrativeArea, administrativeArea],
                    [subLocality, locality],
                    [country, postalCode]]
                .map { (subComponents) -> String in
                    // Combine subcomponents with spaces (e.g. 1030 + City),
                    subComponents.compactMap({ $0 }).joined(separator: " ")
            }
                .filter({ return !$0.isEmpty }) // e.g. no street available
                .joined(separator: ", ") // e.g. "MyStreet 1" + ", " + "1030 City"
        }
    }
}