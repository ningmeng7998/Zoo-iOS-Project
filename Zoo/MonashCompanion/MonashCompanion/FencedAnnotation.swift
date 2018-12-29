//
//  FencedAnnotation.swift
//  MonashCompanion
//
//  Created by ning li on 21/8/18.
//  Copyright © 2018 ning li. All rights reserved.
//

import UIKit
import MapKit
import Contacts

class FencedAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var animal:ZooAnimal?
    
    init(animalName: String, animalDescription: String, lat: Double, long:Double){
        self.title = animalName
        self.subtitle = animalDescription
        self.coordinate = CLLocationCoordinate2D()
        coordinate.latitude = lat
        coordinate.longitude = long
        
        super.init()
    }
}
