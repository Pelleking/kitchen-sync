//
//  ItemsViewController.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-07-19.
//

import Foundation
import UIKit
import CoreData

class ItemsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ItemDetailViewControllerDelegate {

    
    @IBOutlet weak var tableView: UITableView!
    
    var items: [ScannedItemEntity] = []
    var context: NSManagedObjectContext?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ItemsViewController loaded")
        tableView.dataSource = self
        tableView.delegate = self
        
        // listen for the notification
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: "reload"), object: nil)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            tableView.reloadData()
        }
    
    @objc func reloadData() {
        print("reloadin data")
        self.tableView.reloadData()
    }
    
    // MARK: - TableView Data Source Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].name
        return cell
    }
    
    // MARK: - TableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let itemDetailVC = storyBoard.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
            let item = items[indexPath.row]
            
            itemDetailVC.id = item.value(forKey: "id") as? String
            itemDetailVC.name = item.value(forKey: "name") as? String
            itemDetailVC.category = item.value(forKey: "category") as? String
            itemDetailVC.bestBeforeDate = item.value(forKey: "bestbefore") as? Date
        
            // Set the selectedIndexPath property
            itemDetailVC.selectedIndexPath = indexPath
        
            // Set the delegate to self
            itemDetailVC.delegate = self

            itemDetailVC.modalPresentationStyle = .overCurrentContext
            self.present(itemDetailVC, animated: true, completion: nil)
        }
    
    // MARK: - ItemDetailViewControllerDelegate
    
    func didDeleteItem() {
        fetchData()
    }
    
    // MARK: - Fetch Data and Reload
    
    func fetchData() {
        func fetchData() {
            guard let context = context else {
                print("Context is nil")
                return
            }
            
            let fetchRequest: NSFetchRequest<ScannedItemEntity> = ScannedItemEntity.fetchRequest()
            
            do {
                items = try context.fetch(fetchRequest)
                tableView.reloadData() // Reload the table view data
            } catch {
                print("Error fetching data: \(error)")
            }
        }
    }
}

    
    
