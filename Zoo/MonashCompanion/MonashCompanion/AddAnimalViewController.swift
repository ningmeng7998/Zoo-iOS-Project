//
//  AddAnimalViewController.swift
//  MonashCompanion
//
//  Created by ning li on 21/8/18.
//  Copyright © 2018 ning li. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class AddAnimalViewController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, CLLocationManagerDelegate{

    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    
    @IBAction func chosePhoto(_ sender: UIButton) {
        chooseImage(sender.tag)
    }
    @IBAction func choseIcon(_ sender: UIButton) {
        chooseImage(sender.tag)
    }
    
    let CHOSE_ICON = 99
    let CHOSE_PHOTO = 50
    var buttonClicked = 0

    var locationManager: CLLocationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    var managedObjectContext: NSManagedObjectContext?
    
    required init?(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = (appDelegate?.persistentContainer.viewContext)!
        super.init(coder: aDecoder)
        
    }
    
    func chooseImage(_ tag:Int){
        buttonClicked = tag
        let controller = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.camera) {
            controller.sourceType = UIImagePickerControllerSourceType.camera
        }
        else {
            controller.sourceType = UIImagePickerControllerSourceType.photoLibrary
        }
        
        controller.allowsEditing = false
        controller.delegate = self
        self.present(controller, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage]
            as? UIImage {
            if buttonClicked == CHOSE_ICON{
                iconImageView.image = pickedImage
            }else{
                photoImageView.image = pickedImage
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addAnimal(_ sender: Any) {
        var alert: UIAlertController?
        let action = UIAlertAction(title: "OK", style: .default)
        
        let inputNameIsValid = checkName(inputName: nameTextField.text!)
        if (nameTextField.text?.isEmpty)!{
            alert = UIAlertController(title:"Invalid Name", message: "Name cannot be null! ", preferredStyle: .alert)
            alert?.addAction(action)
            self.present(alert!, animated: true, completion: nil)
            return
        }
        if inputNameIsValid == false {
            alert = UIAlertController(title:"Invalid Name", message:"Invalid Name. Only letters are accepted!", preferredStyle: .alert)
            alert?.addAction(action)
            self.present(alert!, animated: true, completion: nil)
            return
        }
        
        let inputDescIsValid = checkAlphNumerics(input: descriptionTextField.text!)
        if inputDescIsValid == false{
            alert = UIAlertController(title:"Input Error", message:"Animal description contains illegal Characters!", preferredStyle: .alert)
            alert?.addAction(action)
            self.present(alert!, animated: true, completion: nil)
            return
        }
        
        let inputLocationIsValid = checkAlphNumerics(input: (locationTextField.text!))
        if (locationTextField.text?.isEmpty)!{
            alert = UIAlertController(title:"Invalid Location", message: "Location cannot be null! ", preferredStyle: .alert)
            alert?.addAction(action)
            self.present(alert!, animated: true, completion: nil)
            return
        }
        if inputLocationIsValid == false{
            alert = UIAlertController(title:"Invalid Location", message: "Only letters and numbers are accepted! ", preferredStyle: .alert)
            alert?.addAction(action)
            self.present(alert!, animated: true, completion: nil)
            return
        }
        
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate{
            let dataBaseContent = delegate.getViewContext()
            let animal = NSEntityDescription.insertNewObject(forEntityName: "ZooAnimal", into: dataBaseContent) as? ZooAnimal
            animal?.name = nameTextField.text
            animal?.animalDescription = descriptionTextField.text
            animal?.location = locationTextField.text
            
            let geocoder = CLGeocoder()
            var coordinates:CLLocationCoordinate2D?
            
            geocoder.geocodeAddressString(locationTextField.text!, completionHandler: {(placemarks, error) -> Void in
                if((error) != nil){
                    print("Error", error ?? "")
                }
                if let placemark = placemarks?.first {
                    coordinates = placemark.location!.coordinate
                    
                }
                if coordinates != nil {
                    print("Contains a value!")
                    print("location text field \(String(describing: self.locationTextField?.text))")
                    print("Lat: \(coordinates?.latitude) -- Long: \(coordinates?.longitude)")
                    animal?.latitude  = (coordinates?.latitude)!
                    animal?.longitude = (coordinates?.longitude)!
                    
                } else {
                    print("Doesn’t contain a value.")
                }
            })
            
            //save iconImage to coreData
            if let iconImage = self.iconImageView.image{
                let imageData = UIImageJPEGRepresentation(iconImage, 1)
                
                animal?.mapIcon = imageData! as NSData
            }else{
                print("iConImageView has no image")
            }
            
            //save PhotoImage to coreData using file path
            if let photoImage = photoImageView.image{
                let folders = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let fileRootPath = folders[0]
                let fileName = "\(UUID.init().uuidString).png"
                let fullFilePath = "\(fileRootPath)/\(fileName)"
                animal?.photoPath = fileName
                print(fullFilePath)
                
                let photoImageData = UIImageJPEGRepresentation(photoImage, 1.0)
                let fullFilePathURL = URL(fileURLWithPath: fullFilePath)
                do{
                    try photoImageData?.write(to: fullFilePathURL)
                }catch let error{
                    print("save image to local folder failed, error = \(error.localizedDescription)")
                }
                
            }
            delegate.saveContext()
            
            NotificationCenter.default.addObserver(self, selector: #selector(popAgain), name: Notification.Name.init("PopAgain"), object: nil)
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let detail = storyboard.instantiateViewController(withIdentifier: "animalDetail") as! AnimalDetialViewController
            detail.modalPresentationStyle = .overCurrentContext
            detail.source = .map
            detail.shouldHideDoneButton = false
            detail.animal = animal
            self.present(detail, animated: true, completion: nil)
        }
    }
    
    
    @objc func popAgain(notification:Notification){
        print("pop again")
        NotificationCenter.default.removeObserver(self)
        let viewControllersInTheStack = self.navigationController?.viewControllers
        for viewController in viewControllersInTheStack!{
            if type(of: viewController) == MapViewController.self{
                print("this view controller is mapViewController")
                let animal = notification.object as? ZooAnimal
                let mapViewController = viewController as? MapViewController
                let animalName = animal?.name ?? "Animal"
                let description = animal?.animalDescription ?? "this is an animal"
                let latitude = animal?.latitude ?? -37.877632
                let longitude:Double = animal?.longitude ?? 145.045374
                let animalAnnotation = FencedAnnotation(animalName: animalName, animalDescription: description, lat: latitude, long: longitude)
                mapViewController?.animalAnnotation = animalAnnotation
            }
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    //Check if the name is valid
    func checkName(inputName: String) -> Bool{
        let allowedCharacters = NSCharacterSet.letters.union(NSCharacterSet.whitespaces)
        let inputChars = NSCharacterSet.init(charactersIn: inputName)
        let result = allowedCharacters.isSuperset(of: inputChars as CharacterSet)
        print("inputName = \(inputName), is superSet ? \(result)")
        return result
    }
    
    func checkAlphNumerics(input: String) -> Bool{
        let allowedChars = NSCharacterSet.alphanumerics.union(NSCharacterSet.whitespaces)
        let inputChars = NSCharacterSet.init(charactersIn: input)
        return allowedChars.isSuperset(of: inputChars as CharacterSet)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowAnimalDetail"{
            let controller = segue.destination as! AnimalDetialViewController
            controller.animal = sender as? ZooAnimal
        }
    }
}

