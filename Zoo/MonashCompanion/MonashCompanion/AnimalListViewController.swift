//
//  AnimalListViewController.swift
//  MonashCompanion
//
//  Created by ning li on 27/8/18.
//  Copyright © 2018 ning li. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class AnimalListViewController: UIViewController, UITableViewDelegate,UITableViewDataSource, UISearchResultsUpdating{
    
    var animalsFromCoreData = [ZooAnimal]()
    var filteredList = [ZooAnimal]()
    var isSearching = false
    var selectedSegement = 1
    
    var mapViewController: MapViewController?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myTabBar: UITabBar!
    
    let cellID = "AnimalCell"
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func selectedSegement(_ sender: UISegmentedControl) {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        
        let context = delegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "ZooAnimal")
        
        if sender.selectedSegmentIndex == 0{
            let sortDescriptor = NSSortDescriptor(key:"name", ascending: true)
            request.sortDescriptors = [sortDescriptor]
        }
        else{
            let sortDescriptor = NSSortDescriptor(key:"name", ascending: false)
            request.sortDescriptors = [sortDescriptor]
        }
        
        do {
            let someDataSorted = (try context.fetch(request) as? [ZooAnimal])!
            print(someDataSorted)
            animalsFromCoreData = someDataSorted
            print("there are \(animalsFromCoreData.count) in database")
            tableView.reloadData()
        } catch let error as NSError{
            print("fetching failed")
        }

    }
    
    
    var mySearchController:UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        getZooAnimalsFromCoreData()
        filteredList = animalsFromCoreData
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getZooAnimalsFromCoreData()
        
        mySearchController = UISearchController(searchResultsController: nil)
        mySearchController?.searchResultsUpdater = self
        mySearchController?.obscuresBackgroundDuringPresentation = false
        mySearchController?.searchBar.placeholder = "Search Animal"
        mySearchController?.searchBar.showsCancelButton = true
        
        navigationItem.searchController = mySearchController
        
        
        
        tableView.reloadData()
    }

    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
            self.mapViewController?.showAnnotations()
            tableView.reloadData()
        } catch let error as NSError{
            print("fetching failed")
        }
    }
    
    func updateSearchResults(for searchController: UISearchController){
        
        self.isSearching = true
        if let searchText = searchController.searchBar.text,
            searchText.count > 0{
            filteredList = animalsFromCoreData.filter({(animal: ZooAnimal) -> Bool in
                return (animal.name?.contains(searchText))!
            })
        }
        else{
            filteredList = animalsFromCoreData
        }
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("has \(animalsFromCoreData.count) in table view")
        if isSearching == true{
            return filteredList.count
        }else{
            return animalsFromCoreData.count
        }
    }
    
    //configure the cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! AnimalCell
        var animal:ZooAnimal?
        if isSearching == true{
            animal = filteredList[indexPath.row]
        }else{
            animal = animalsFromCoreData[indexPath.row]
        }
        
  
        cell.animalNameLabel?.text = animal?.name
        cell.animalDescriptionLabel?.text = animal?.animalDescription
        if let imageData = animal?.mapIcon{
            let image = UIImage(data: imageData as Data)
            cell.iconImage?.image = image
        }

        cell.accessoryType = .detailDisclosureButton
        return cell
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        var animal: ZooAnimal?
        animal = self.animalsFromCoreData[indexPath.row]

        performSegue(withIdentifier: "ShowAnimalDetailFromAnimalListSegue", sender: animal)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var animal: ZooAnimal?
        if isSearching == true{
            animal = self.filteredList[indexPath.row]
        }else{
            animal = self.animalsFromCoreData[indexPath.row]
        }
        
        let annotation: FencedAnnotation = FencedAnnotation(animalName: (animal?.name)!, animalDescription: (animal?.animalDescription)!, lat: (animal?.latitude)!, long: (animal?.longitude)!)
        
        
        if UIDevice.current.orientation.isLandscape {
            self.mapViewController?.focusOn(annotation: annotation as MKAnnotation)
        } else {
            self.mySearchController?.hidesNavigationBarDuringPresentation = false
            self.performSegue(withIdentifier: "ShowAnimalOnMapSegue", sender: annotation)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "AddAnimalFromList"){
            let controller = segue.destination as! AddAnimalViewController
        }
        else if segue.identifier == "ShowAnimalDetailFromAnimalListSegue"{
            let controller = segue.destination as! AnimalDetialViewController
            controller.shouldHideDoneButton = true
            controller.animal = sender as? ZooAnimal
        }
        else if segue.identifier == "ShowAnimalOnMapSegue"{
            let controller = segue.destination as! MapViewController
            controller.animalAnnotation = sender as? FencedAnnotation
        }
    }
}
