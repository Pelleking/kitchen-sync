//
//  ViewController.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-05-28.


import UIKit
import Foundation
import CoreData

class MyScannedItem: Codable, Equatable {
    var id: String
    var name: String
    var category: String
    var imageBase64: String
    var bestbefore: Date
    var scandate: Date
    
    init(id: String, name: String, category: String, imageBase64: String, bestbefore: Date, scandate: Date) {
        self.id = id
        self.name = name
        self.category = category
        self.imageBase64 = imageBase64
        self.bestbefore = bestbefore
        self.scandate = scandate
    }
        static func == (lhs: MyScannedItem, rhs: MyScannedItem) -> Bool {
            return lhs.id == rhs.id &&
                lhs.name == rhs.name &&
                lhs.category == rhs.category &&
                lhs.bestbefore == rhs.bestbefore &&
                lhs.scandate == rhs.scandate
    }
    
    
    convenience init(name: String, category: String, imageBase64: String, bestbefore: Date, scandate: Date) {
        let id = "\(name)-\(bestbefore.timeIntervalSince1970)-\(scandate.timeIntervalSince1970)"
        self.init(id: id, name: name, category: category, imageBase64: imageBase64, bestbefore: bestbefore, scandate: scandate)
    }
    
    var image: UIImage? {
        guard let imageData = Data(base64Encoded: imageBase64) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}


class ViewController: UIViewController, ScanningViewControllerDelegate {
    var context: NSManagedObjectContext?

    
    var fetchedResultsController: NSFetchedResultsController<ScannedItemEntity>!
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<ScannedItemEntity> = ScannedItemEntity.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "scandate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchLimit = 0


        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Fetch Failed: \(error)")
        }
    }

    var scannedItems: [String: [MyScannedItem]] = [:]
    var scanID: String?
    var shouldDisplayPlaceholder = false
    
    @IBOutlet weak var tableView: UITableView!
    
    //hamburgermenu button
    var transparentButton: UIButton?
    var tapGesture: UITapGestureRecognizer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.backgroundColor = .clear


        //lisening for change in the core data
      //  NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: "reload"), object: nil)

        //hamburgermenu
        // Set up gesture recognizers
            setupGestureRecognizers()
        

        
        
        func setUpFetchedResultsController() {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<ScannedItemEntity> = ScannedItemEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: #keyPath(ScannedItemEntity.scandate), ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            fetchRequest.fetchLimit = 0
            
            fetchedResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            fetchedResultsController.delegate = self
            
            do {
                try fetchedResultsController.performFetch()
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
        
        updateplaceholder()

    }
    
    //check placeholder
    func updateplaceholder() {
        if fetchedResultsController.fetchedObjects?.isEmpty == true {
            shouldDisplayPlaceholder = true
        } else {
            shouldDisplayPlaceholder = false
        }
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupGestureRecognizers()
    }
    
    func setupGestureRecognizers() {
        let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        recognizer.direction = .left
        self.view.addGestureRecognizer(recognizer)

        let swipeRightRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeRightRecognizer.direction = .right
        self.view.addGestureRecognizer(swipeRightRecognizer)
    }
    
    var isMenuOpen = false
    
    @objc func handleSwipe(_ recognizer: UISwipeGestureRecognizer) {
        if recognizer.direction == .left, !isMenuOpen {
            // Trigger menu opening
            openMenu()
        }
    }

    @objc func handleSwipeRight(_ recognizer: UISwipeGestureRecognizer) {
        if recognizer.direction == .right, isMenuOpen {
            // Trigger menu closing
            closeMenu()
        }
    }
    
    @IBAction func MenuOpenButton(_ sender: Any) {
        openMenu()
    }
    

    @objc func handleTapGesture(_ recognizer: UITapGestureRecognizer?) {
        recognizer?.cancelsTouchesInView = false
            let slideMenuView = children.last?.view
            UIView.animate(withDuration: 0.3, animations: {
               slideMenuView?.frame = CGRect(x: self.view.frame.width, y: 0, width: self.view.frame.width * 0.6, height: self.view.frame.height)
            }) { _ in
                self.children.last?.willMove(toParent: nil)
                slideMenuView?.removeFromSuperview()
                self.children.last?.removeFromParent()
            }
            
        
    }

    func openMenu() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let slideMenuVC = storyboard.instantiateViewController(withIdentifier: "SlideMenuViewController") as? SlideMenuViewController else {
            print("Could not instantiate SlideMenuViewController")
            return
        }

        /* Hide the SlideMenuViewController outside the visible area ready to be animated */
        slideMenuVC.view.frame = CGRect(x: self.view.frame.width, y: 0, width: self.view.frame.width * 0.6, height: self.view.frame.height)
        
        view.addSubview(slideMenuVC.view)
        addChild(slideMenuVC)
        slideMenuVC.didMove(toParent: self)
        
        // Animate the side menu view to slide from right
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            slideMenuVC.view.frame = CGRect(x: self.view.frame.width * 0.4, y: 0, width: self.view.frame.width * 0.6, height: self.view.frame.height)
        }, completion: nil)
        
        self.transparentButton = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.4, height: self.view.frame.height))
        transparentButton?.addTarget(self, action: #selector(outsideMenuTapped), for: .touchUpInside)
        self.view.addSubview(transparentButton!)
        isMenuOpen = true
    }

    
    @objc func outsideMenuTapped() {
        // Trigger menu closing
        closeMenu()
    }

    @objc func closeMenu() {
        // get reference to slideMenuVC
      /*  guard let slideMenuVC = children.last as? SlideMenuViewController else {
            return
        }

        // remove tap gesture and the transparent button
        slideMenuVC.view.removeGestureRecognizer(tapGesture!)
        */
       self.transparentButton?.removeFromSuperview()
        
        handleTapGesture(nil)
        
        isMenuOpen = false
        
        setupGestureRecognizers()  //Reinitialize the gestures after closing the menu


    }
    

    func loadImageOrWhiteSquare(named name: String, size: CGSize) -> UIImage? {
        if let image = UIImage(named: name) {
            return image
        } else {
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { (context) in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
            return image
        }
    }

    func didScanItem(_ item: ScannedItem) {

        // Set the flag to false to indicate that the placeholder cell should not be displayed
        shouldDisplayPlaceholder = false

        // Reload the table view data
        tableView.reloadData()
        
        // Generate a unique ID for the scanned item
        let id = UUID().uuidString
        
        // Create a new instance of MyScannedItem with the name, best before date, and current date as the scan date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let bestbefore = dateFormatter.date(from: item.bestbefore) else {
            print("Error: Unable to convert scan date string to date object")
            return
        }
        
        let image = loadImageOrWhiteSquare(named: "\(item.name)-productimage", size: CGSize(width: 100, height: 100))
        if let imageData = image?.pngData() {
            let base64String = imageData.base64EncodedString()
            let myScannedItem = MyScannedItem(id: id, name: item.name, category: item.category, imageBase64: base64String, bestbefore: bestbefore, scandate: Date())
            
            // Add the new MyScannedItem to the array of items for the current scan ID, or create a new scan ID if it doesn't exist
            if var itemsForScan = scannedItems[scanID ?? ""] {
                itemsForScan.append(myScannedItem)
                scannedItems[scanID ?? ""] = itemsForScan
            } else {
                scannedItems[scanID ?? ""] = [myScannedItem]
            }
            
            // Update the scannedItems dictionary with new imageBase64 value for each MyScannedItem
            scannedItems = scannedItems.mapValues { items in
                items.map { item in
                    let newItem = item
                    newItem.imageBase64 = "newBase64Value"
                    return newItem
                }
            }
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext

            let entity = NSEntityDescription.entity(forEntityName: "ScannedItemEntity", in: context)!
            let newRecord = NSManagedObject(entity: entity, insertInto: context)

            // Set the properties
            newRecord.setValue(myScannedItem.id, forKey: "id")
            newRecord.setValue(myScannedItem.category, forKey: "category")
            newRecord.setValue(myScannedItem.name, forKey: "name")
            newRecord.setValue(myScannedItem.imageBase64, forKey: "imageBase64")
            newRecord.setValue(myScannedItem.bestbefore, forKey: "bestbefore")
            newRecord.setValue(myScannedItem.scandate, forKey: "scandate")

            do {
               try context.save()
            } catch {
               print("Failed saving")
            }

         
            
            // Save the updated scannedItems dictionary to local storage
            //  saveLocallyStoredItems(scannedItems)
            
            dismiss(animated: true, completion: nil)
        } else {
            print("Error: Unable to load image or create white square image")
        }
    }


    func showScanner() {
        let scanner = ScanningViewController()
        scanner.delegate = self
        present(scanner, animated: true, completion: nil)
    }

    @IBAction func showScannerButtonTapped(_ sender: UIButton) {
        showScanner()
    }
    


}

extension ViewController: UITableViewDataSource {
    
    
    // func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    //     guard let sections = fetchedResultsController.sections else { return 0 }
    //     let sectionInfo = sections[section]
    //     //return sectionInfo.numberOfObjects
    //     return min(fetchedResultsController.fetchedObjects?.count ?? 0, 5)
    // }
    /*
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else { return 0 }
        let sectionInfo = sections[section]
        if sectionInfo.numberOfObjects == 0 {
            return 0
        } else {
            return min(fetchedResultsController.fetchedObjects?.count ?? 0, 5)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = fetchedResultsController.fetchedObjects?[indexPath.row]
        cell.textLabel?.text = item?.name
        let customColor = UIColor(hexString: "#747391")
        cell.backgroundColor = customColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = fetchedResultsController.fetchedObjects?.count ?? 0
        return count == 0 ? 1 : count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let count = fetchedResultsController.fetchedObjects?.count ?? 0
        if count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceholderCell", for: indexPath)
            cell.textLabel?.text = "No Scanned Items"
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let item = fetchedResultsController.fetchedObjects?[indexPath.row]
            cell.textLabel?.text = item?.name
            let customColor = UIColor(hexString: "#747391")
            cell.backgroundColor = customColor
            return cell
        }
    }

    */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = fetchedResultsController.fetchedObjects?.count ?? 0
        return shouldDisplayPlaceholder ? 1 : count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if shouldDisplayPlaceholder {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceholderCell", for: indexPath)
            cell.textLabel?.text = "No Scanned Items"
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let item = fetchedResultsController.fetchedObjects?[indexPath.row]
            cell.textLabel?.text = item?.name
            let customColor = UIColor(hexString: "#747391")
            cell.backgroundColor = customColor
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let item = fetchedResultsController.object(at: indexPath)
            scanID = item.value(forKey: "id") as? String
            print("scanID: \(String(describing: scanID))")
            
            for (scanIdInDict, array) in scannedItems {
                // Obtain the index of the item with matching scanId in the array
                if let index = array.firstIndex(where: { element in element.id == scanID }) {
                    // Remove the item from the array
                    scannedItems[scanIdInDict]?.remove(at: index)
                    
                    // If the array is empty, remove the scanId from scannedItems
                    if scannedItems[scanIdInDict]?.isEmpty == true {
                        scannedItems.removeValue(forKey: scanIdInDict)
                    }
                }
            }
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            // Fetch the NSManagedObject to be deleted
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ScannedItemEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", scanID!)
            
            do {
                let fetchResult = try context.fetch(fetchRequest)
                if let objectToDelete = fetchResult.first as? NSManagedObject {
                    context.delete(objectToDelete)
                    do {
                      // Save the changes to the context
                      try context.save()
                      tableView.reloadData()
                      print("deleted from coredata")
                    } catch {
                      print("Failed saving after deletion: \(error)")
                    }
                }
            } catch {
                print("Failed deleting: \(error)")
            }

        }
    }

    
    func deleteItem(/*at indexPath: IndexPath,*/scanId: String) {
        
        // Iterate through all scanIDs in scannedItems
        for (scanIdInDict, array) in scannedItems {
            // Obtain the index of the item with matching scanId in the array
            if let index = array.firstIndex(where: { element in element.id == scanId }) {
                // Remove the item from the array
                scannedItems[scanIdInDict]?.remove(at: index)
                
                // If the array is empty, remove the scanId from scannedItems
                if scannedItems[scanIdInDict]?.isEmpty == true {
                    scannedItems.removeValue(forKey: scanIdInDict)
                }
            }
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Fetch the NSManagedObject to be deleted
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ScannedItemEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", scanId)
        
        do {
            let fetchResult = try context.fetch(fetchRequest)
            if let objectToDelete = fetchResult.first as? NSManagedObject {
                context.delete(objectToDelete)
                do {
                  // Save the changes to the context
                  try context.save()
                  print("deleted from coredata")
                } catch {
                  print("Failed saving after deletion: \(error)")
                }
            }
        } catch {
            print("Failed deleting: \(error)")
        }

        
        // Delete the row from the table view
        var indexPathToDelete: IndexPath?

        for (section, (scanIdInDict, array)) in scannedItems.enumerated() {
            if scanIdInDict == scanId {
                for (row, _) in array.enumerated() {
                    indexPathToDelete = IndexPath(row: row, section: section)
                    break
                }
            }
        }

        if let indexPath = indexPathToDelete {
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()

        }
            

        
        // Save the updated scannedItems array to local storage
        //saveLocallyStoredItems(scannedItems)
        
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let count = fetchedResultsController.fetchedObjects?.count ?? 0
        if count == 0 {
            updateplaceholder()
        } else {
            switch type {
            case .insert:
                if let newIndexPath = newIndexPath {
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
            case .delete:
                if let indexPath = indexPath {
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            case .update:
                if let indexPath = indexPath {
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            case .move:
                if let indexPath = indexPath {
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
                if let newIndexPath = newIndexPath {
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
            @unknown default:
                fatalError("Unknown NSFetchedResultsChangeType")
            }
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        tableView.reloadData()
    }
}

extension UIColor {
    convenience init(hexString: String) {
        let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
}




/*
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Return the current scan ID as the section header title
        return scannedItems.keys.sorted()[section]
    }
}

extension ViewController {
    func saveLocallyStoredItems(_ items: [String: [MyScannedItem]]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            UserDefaults.standard.set(data, forKey: "scannedItems")
        } catch {
            print("Error: Unable to encode and save scanned items to local storage")
        }
    }
    
    func loadLocallyStoredItems() -> [String: [MyScannedItem]] {
        var loadedItems: [String: [MyScannedItem]] = [:]
        
        if let data = UserDefaults.standard.data(forKey: "scannedItems") {
            do {
                let decoder = JSONDecoder()
                loadedItems = try decoder.decode([String: [MyScannedItem]].self, from: data)
            } catch {
                print("Error: Unable to decode and load scanned items from local storage")
            }
        }
        
        return loadedItems
    }

}
*/
