//
//  AnimalDetialViewController.swift
//  MonashCompanion
//
//  Created by ning li on 21/8/18.
//  Copyright © 2018 ning li. All rights reserved.
//

import UIKit
import MapKit
enum SourceType {
    case map
    case list
}

class AnimalDetialViewController: UIViewController{
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var animalNameLabel: UILabel!
    @IBOutlet weak var animalDescriptionLabel: UILabel!
    @IBOutlet weak var animalLocationLabel: UILabel!
    
    
    var animal: ZooAnimal?
    var source:SourceType?
    var shouldHideDoneButton:Bool = false
    
    @IBAction func removeAnimalButton(_ sender: Any) {
        
                let alert = UIAlertController(title: "Delete", message: "Do you Want to delete this animal?", preferredStyle: .alert)
        
                let yesAction = UIAlertAction(title: "YES", style: .default) { (action) in
                    if let delegate = UIApplication.shared.delegate as? AppDelegate{
                        let context = delegate.getViewContext()
                        let selectedAnimal = self.animal
                        context.delete(selectedAnimal!)
                        delegate.saveContext()
                        
                        if self.navigationController == nil{
                            self.dismiss(animated: true, completion: {
                                NotificationCenter.default.post(Notification.init(name: Notification.Name(rawValue: "PopAgain")))
                            })
                        }else{
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
        
                let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
                alert.addAction(yesAction)
                alert.addAction(noAction)
                self.present(alert, animated: true, completion: nil)
    }
    
    //This button will only be shown if source is map view
    @IBAction func doneButtonTapped(_ sender: Any) {
        guard let source = source else{
            return
        }
        
        if source == .map {
            self.dismiss(animated: true, completion: {
                
                var coordinate = CLLocationCoordinate2D()
                coordinate.latitude = (self.animal?.latitude)!
                coordinate.longitude = (self.animal?.longitude)!
                NotificationCenter.default.post(name: NSNotification.Name.init("PopAgain"), object: self.animal)
            })
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.isHidden = shouldHideDoneButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        if let name = animal?.name, let desc = animal?.animalDescription, let location = animal?.location{
            animalNameLabel.text = name
            animalDescriptionLabel.text = desc
            animalLocationLabel.text = location
        }
        print("photoPath for \(animal?.name) == \(animal?.photoPath)")
        
        if let photoName = animal?.photoPath{
            let folders = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let fileRootPath = folders[0]
            print("photo loaded")
            let photoURL = URL(fileURLWithPath: "\(fileRootPath)/\(photoName)")
            do{
                let imageData = try Data(contentsOf: photoURL)
                photoImageView.image = UIImage(data: imageData)
            }catch let error{
                print("load image file failed, error = \(error.localizedDescription)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
