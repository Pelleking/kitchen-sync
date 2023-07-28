//
//  BestBeforeViewController.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-07-28.
//

import Foundation
import UIKit
import CoreData

class BestBeforeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    var fetchedResultsController: NSFetchedResultsController<ScannedItemEntity>?
    var category: String?
    var items: [ScannedItemEntity] = []
    var item: ScannedItemEntity?
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ItemsViewController loaded")
        tableView.dataSource = self
        tableView.delegate = self
        self.tableView.backgroundColor = .clear

        setupFetchedResultsController()
        fetchData()
    }
    
    func setupFetchedResultsController() {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            print("Context is nil")
            return
        }
            
        let fetchRequest: NSFetchRequest<ScannedItemEntity> = ScannedItemEntity.fetchRequest()
            
        if let item = item {
            let namePredicate = NSPredicate(format: "name == %@", item.name!)
            let datePredicate: NSPredicate
            if let date = item.bestbefore {
                datePredicate = NSPredicate(format: "bestbefore == %@", date as NSDate)
            } else {
                datePredicate = NSPredicate(format: "bestbefore = nil")
            }
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [namePredicate, datePredicate])
        }
        
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
            
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self
            
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("Error fetching data: \(error)")
        }
    }

    
    // MARK: - TableView Data Source Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.fetchedObjects?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        
        guard let item = fetchedResultsController?.object(at: indexPath) else {
            return cell // item can't be fetched, return the dequeued cell.
        }
        
        // If we're here, item is not nil and we can unwrap name and bestbefore
        if let name = item.name, let bestBeforeDate = item.bestbefore {
            let bestBeforeDateString = formatDateToString(date: bestBeforeDate)
            cell.textLabel?.text = "\(name) - \(bestBeforeDateString)"
        }

        let customColor = UIColor(hexString: "#747391")
        cell.backgroundColor = customColor
        
        return cell
    }
    
    func formatDateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }



    // MARK: - TableView Delegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let itemDetailVC = storyBoard.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        if let item = fetchedResultsController?.object(at: indexPath) {
            itemDetailVC.id = item.value(forKey: "id") as? String
            itemDetailVC.name = item.value(forKey: "name") as? String
            itemDetailVC.category = item.value(forKey: "category") as? String
            itemDetailVC.bestBeforeDate = item.value(forKey: "bestbefore") as? Date
            itemDetailVC.modalPresentationStyle = .overCurrentContext
            self.present(itemDetailVC, animated: true, completion: nil)
        }
    }

    // MARK: - Fetch Data
    func fetchData() {
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("Error fetching data: \(error)")
        }
    }


}
extension BestBeforeViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
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
            if let oldIndexPath = indexPath, let newIndexPath = newIndexPath {
                // Remove from previous position and insert into new position
                tableView.deleteRows(at: [oldIndexPath], with: .automatic)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }

        @unknown default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

