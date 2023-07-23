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
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
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
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()

        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")


        //lisening for change in the core data
      //  NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: "reload"), object: nil)

        

        func setUpFetchedResultsController() {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<ScannedItemEntity> = ScannedItemEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: #keyPath(ScannedItemEntity.name), ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
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
            
            tableView.reloadData()
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
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else { return 0 }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = item.name
        return cell
    }

    
    
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Get the scanId of the section where deletion is happening
            guard let scanId = scanID, var itemArr = scannedItems[scanId] else { return }
            
            // Check if array has enough items to avoid the 'Index out of range' error
            guard indexPath.row < itemArr.count else { return }
            
            // Get the item to remove
            let itemToRemove = itemArr[indexPath.row]
            
            // Get the id of the item to remove
            let itemIdToRemove = itemToRemove.id
            
            // Remove the item from the array
            itemArr.remove(at: indexPath.row)
            scannedItems[scanId] = itemArr
            
            // If the array is empty, remove the scanId from scannedItems
            if itemArr.isEmpty {
                scannedItems.removeValue(forKey: scanId)
            }
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            // Fetch the NSManagedObject to be deleted
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ScannedItemEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", itemIdToRemove)  // Use itemIdToRemove here
            
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
        //tableView.deleteRows(at: [indexPath], with: .fade)
        
        // Save the updated scannedItems array to local storage
        //saveLocallyStoredItems(scannedItems)
        
    }
}
    extension ViewController: NSFetchedResultsControllerDelegate {

        func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            tableView.beginUpdates()
        }
        
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            tableView.endUpdates()
        }
        
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                                 didChange anObject: Any,
                                 at indexPath: IndexPath?,
                                 for type: NSFetchedResultsChangeType,
                                 newIndexPath: IndexPath?) {

            switch type {
            case .insert:
                guard let newIndexPath = newIndexPath else { return }
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            case .delete:
                guard let indexPath = indexPath else { return }
                tableView.deleteRows(at: [indexPath], with: .automatic)
            case .update:
                guard let indexPath = indexPath else { return }
                tableView.reloadRows(at: [indexPath], with: .automatic)
            case .move:
                guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
                tableView.moveRow(at: indexPath, to: newIndexPath)
            @unknown default:
              return
            }
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
