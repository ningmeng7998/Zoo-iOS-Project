//
//  ZooAnimal+CoreDataProperties.swift
//  MonashCompanion
//
//  Created by ning li on 27/8/18.
//  Copyright © 2018 ning li. All rights reserved.
//
//

import Foundation
import CoreData


extension ZooAnimal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ZooAnimal> {
        return NSFetchRequest<ZooAnimal>(entityName: "ZooAnimal")
    }

    @NSManaged public var animalDescription: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var mapIcon: NSData?
    @NSManaged public var name: String?
    @NSManaged public var photoPath: String?
    @NSManaged public var location: String?

}
