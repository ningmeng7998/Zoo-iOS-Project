//
//  MapViewController.swift
//  MonashCompanion
//
//  Created by ning li on 21/8/18.
//  Copyright © 2018 ning li. All rights reserved.
//

import UIKit
import MapKit
import CoreData

protocol AddInitialAnimalProtocol{
    func addInitialAnimalData()
}


class MapViewController: UIViewController, CLLocationManagerDelegate{

    @IBOutlet weak var mapView: MKMapView!
    
    
    var geoFenceRegion: CLCircularRegion?
    var locationManager: CLLocationManager = CLLocationManager()
    var animalAnnotation: FencedAnnotation?
    var geofences: NSMutableArray?
    
    var selectedAnimal: ZooAnimal?

    var mapViewController: MapViewController?
    var animalsFromCoreData = [ZooAnimal]()
    let initialLocation = CLLocation(latitude: -37.877632, longitude: 145.045374)


    var managedObjectContext: NSManagedObjectContext?
    
    required init?(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = (appDelegate?.persistentContainer.viewContext)!
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set initial location
        showAnnotations()
        centerMapOnLocation(location: initialLocation)

        //initialize animal list
        if isAppAlreadyLaunchedOnce() == false{
            addInitialAnimalData()
        }

        mapView.delegate = self
    
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        createGeoLocations()
    }
    
    func createGeoLocations(){
        getZooAnimalsFromCoreData()
        let defaultGeoFenceRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(-37.876818, 145.044511), radius: 100, identifier: "Tiger")
        for animal in animalsFromCoreData{
            geoFenceRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(animal.latitude, animal.longitude), radius: 10, identifier: animal.name!)
            geofences?.add(geoFenceRegion ?? defaultGeoFenceRegion)
            geoFenceRegion?.notifyOnEntry = true
            locationManager.startMonitoring(for: geoFenceRegion as! CLCircularRegion)
            print("\(String(describing: animal.name)) geolocations \(String(describing: geoFenceRegion))")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Did enter region \(region)")
        let alert = UIAlertController(title: "Movement Detected!", message: "You have approached to \(String(describing: region.identifier))", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion){
        print("Did exit region")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("location is being updated")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if animalAnnotation != nil{
            showAnnotations()
            focusOn(annotation: animalAnnotation!)
        }
        else{
            centerMapOnLocation(location: initialLocation)
        }
    }
    
    let regionRadius: CLLocationDistance = 500
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func addAnnotation(annotation: MKAnnotation){
        self.mapView.addAnnotation(annotation)
    }
    
    func focusOn(annotation: MKAnnotation){
        let existedAnnotations = mapView.annotations
        let matchedAnnotation = existedAnnotations.filter { (oldAnnotation) -> Bool in
            if oldAnnotation.coordinate.longitude == annotation.coordinate.longitude,oldAnnotation.coordinate.latitude == annotation.coordinate.latitude{
                return true
            }
            return false
        }
        if matchedAnnotation.count == 1,let first = matchedAnnotation.first{
            print("focus on the annotation")
            
            self.mapView.centerCoordinate = first.coordinate
            self.mapView.selectAnnotation(first, animated:true)
        }else{
            print("no annotation to focus")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func getZooAnimalsFromCoreData(){
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        
        let context = delegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "ZooAnimal")
        do {
            animalsFromCoreData = (try context.fetch(request) as? [ZooAnimal])!
            print("there are \(animalsFromCoreData.count) in database")
        } catch let error as NSError{
            print("fetching failed")
        }
    }
    
    func showAnnotations(){
        var annotations = [FencedAnnotation]()
        annotations.removeAll()
        let oldAnnotations = mapView.annotations
        mapView.removeAnnotations(oldAnnotations)
        
        getZooAnimalsFromCoreData()
        
        for animal in animalsFromCoreData{
            let animalLocation: FencedAnnotation = FencedAnnotation(animalName: animal.name!, animalDescription: animal.animalDescription!, lat: animal.latitude, long: animal.longitude)
            animalLocation.animal = animal
            annotations.append(animalLocation)
        }
        
        mapView.addAnnotations(annotations)
        print("there are : \(annotations.count) annotations ")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if(segue.identifier == "AddAnimal"){
            let controller = segue.destination as! AddAnimalViewController
        }
        if (segue.identifier == "ShowAnimalDetailFromMapSegue" )
        {
            let destination = segue.destination as! AnimalDetialViewController
            destination.shouldHideDoneButton = true
            destination.animal = sender as? ZooAnimal
        }
    }
}


extension MapViewController:MKMapViewDelegate{

      func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? FencedAnnotation else { return nil }
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
          as? MKMarkerAnnotationView {
          dequeuedView.annotation = annotation
          let rect = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
          let imageView = UIImageView(frame: rect)
          if let imageData = annotation.animal?.mapIcon{
            let image = UIImage(data: imageData as Data)
            imageView.image = image
            }
          dequeuedView.leftCalloutAccessoryView = imageView
          view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            
            let disclosureButton = UIButton(type: .detailDisclosure)
            view.rightCalloutAccessoryView = disclosureButton
            
            let rect = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
            let imageView = UIImageView(frame: rect)
            if let imageData = annotation.animal?.mapIcon{
                let image = UIImage(data: imageData as Data)
                imageView.image = image
            }
            view.leftCalloutAccessoryView = imageView
        }
        return view
      }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? FencedAnnotation else { return }
        var animal: ZooAnimal?
        animal = annotation.animal
        
        performSegue(withIdentifier: "ShowAnimalDetailFromMapSegue", sender: animal)
    }
    
    func addInitialAnimalData(){
        var animal = NSEntityDescription.insertNewObject(forEntityName: "ZooAnimal", into: managedObjectContext!) as! ZooAnimal
        
        let folders = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let fileRootPath = folders[0]
    
        animal.name = "Tiger"
        animal.animalDescription = "The tiger (Panthera tigris) is the largest cat species."
        animal.location = "Monash University caulfield library"
        animal.latitude = -37.877171
        animal.longitude = 145.045273
        var iconImage = #imageLiteral(resourceName: "icon_tiger")
        var imageData = UIImageJPEGRepresentation(iconImage, 1)
        animal.mapIcon = imageData! as NSData
        var photoImage = #imageLiteral(resourceName: "tigerImage")
        var fileName = "\(UUID.init().uuidString).png"
        var fullFilePath = "\(fileRootPath)/\(fileName)"
        animal.photoPath = fileName
        var photoImageData = UIImageJPEGRepresentation(photoImage, 1.0)
        var fullFilePathURL = URL(fileURLWithPath: fullFilePath)
        do{
            try photoImageData?.write(to: fullFilePathURL)
        }catch let error{
            print("save image to local folder failed, error = \(error.localizedDescription)")
        }


        animal = NSEntityDescription.insertNewObject(forEntityName: "ZooAnimal", into: managedObjectContext!) as! ZooAnimal
        animal.name = "Wolf"
        animal.animalDescription = "Gray wolves, or timber wolves, are canines with long bushy tails that are black-tipped. "
        animal.location = "Monash University Museum Of Art"
        animal.latitude = -37.877014
        animal.longitude = 145.046112
        iconImage = #imageLiteral(resourceName: "icon_wolf")
        imageData = UIImageJPEGRepresentation(iconImage, 1)
        animal.mapIcon = imageData! as NSData
        photoImage = #imageLiteral(resourceName: "wolfImage")
        fileName = "\(UUID.init().uuidString).png"
        animal.photoPath = fileName
        photoImageData = UIImageJPEGRepresentation(photoImage, 1.0)
        fullFilePath = "\(fileRootPath)/\(fileName)"
        fullFilePathURL = URL(fileURLWithPath: fullFilePath)
        do{
            try photoImageData?.write(to: fullFilePathURL)
        }catch let error{
            print("save image to local folder failed, error = \(error.localizedDescription)")
        }

        animal = NSEntityDescription.insertNewObject(forEntityName: "ZooAnimal", into: managedObjectContext!) as! ZooAnimal
        animal.name = "Rabbit"
        animal.animalDescription = "Rabbits are small, furry, mammals with long ears, short fluffy tails, and strong, large hind legs."
        animal.location = "Monash University Caulfield Building H"
        animal.latitude = -37.877010
        animal.longitude = 145.044266
        iconImage = #imageLiteral(resourceName: "icon_rabbit")
        imageData = UIImageJPEGRepresentation(iconImage, 1)
        animal.mapIcon = imageData! as NSData
        photoImage = #imageLiteral(resourceName: "rabbitImage")
        fileName = "\(UUID.init().uuidString).png"
        animal.photoPath = fileName
        photoImageData = UIImageJPEGRepresentation(photoImage, 1.0)
        fullFilePath = "\(fileRootPath)/\(fileName)"
        fullFilePathURL = URL(fileURLWithPath: fullFilePath)
        do{
            try photoImageData?.write(to: fullFilePathURL)
        }catch let error{
            print("save image to local folder failed, error = \(error.localizedDescription)")
        }

        animal = NSEntityDescription.insertNewObject(forEntityName: "ZooAnimal", into: managedObjectContext!) as! ZooAnimal
        animal.name = "Elephant"
        animal.animalDescription = "Elephants are the largest land animals on Earth. "
        animal.location = "Monash University MONSU Caulfield Student Union"
        animal.latitude = -37.877185
        animal.longitude = 145.043094
        iconImage = #imageLiteral(resourceName: "icon_elephant")
        imageData = UIImageJPEGRepresentation(iconImage, 1)
        animal.mapIcon = imageData! as NSData
        photoImage = #imageLiteral(resourceName: "elephantImage")
        fileName = "\(UUID.init().uuidString).png"
        animal.photoPath = fileName
        photoImageData = UIImageJPEGRepresentation(photoImage, 1.0)
        fullFilePath = "\(fileRootPath)/\(fileName)"
        fullFilePathURL = URL(fileURLWithPath: fullFilePath)
        do{
            try photoImageData?.write(to: fullFilePathURL)
        }catch let error{
            print("save image to local folder failed, error = \(error.localizedDescription)")
        }
        
        animal = NSEntityDescription.insertNewObject(forEntityName: "ZooAnimal", into: managedObjectContext!) as! ZooAnimal
        animal.name = "Monkey"
        animal.animalDescription = "Monkeys are non-hominoid simians, consisting of about 260 known living species. "
        animal.location = "Monash University Caulfield Plaza"
        animal.latitude = -37.876122
        animal.longitude = 145.042930
        iconImage = #imageLiteral(resourceName: "icon_monkey")
        imageData = UIImageJPEGRepresentation(iconImage, 1)
        animal.mapIcon = imageData! as NSData
        photoImage = #imageLiteral(resourceName: "monkeyImage")
        fileName = "\(UUID.init().uuidString).png"
        animal.photoPath = fileName
        photoImageData = UIImageJPEGRepresentation(photoImage, 1.0)
        fullFilePath = "\(fileRootPath)/\(fileName)"
        fullFilePathURL = URL(fileURLWithPath: fullFilePath)
        do{
            try photoImageData?.write(to: fullFilePathURL)
        }catch let error{
            print("save image to local folder failed, error = \(error.localizedDescription)")
        }
        

        do{
            try managedObjectContext?.save()
        }
        catch let error{
            print("Could not save Core Data: \(error)")
        }
    }
    
    func isAppAlreadyLaunchedOnce()->Bool{
        let defaults = UserDefaults.standard
        if let _ = defaults.string(forKey: "isAppAlreadyLaunchedOnce"){
            print("App already launched")
            return true
        }else{
            defaults.set(true, forKey: "isAppAlreadyLaunchedOnce")
            print("App launched first time")
            return false
        }
    }
}


