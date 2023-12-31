//
//  StatsPage.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-07-18.
//
import Foundation
import CoreData
import UIKit
class StatsPage: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    @IBOutlet weak var itemCountLabelui: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var itemsTableView: UITableView!


    var categories: [String: [ScannedItemEntity]] = [:]
    var categoryNames: [String] = []
    var groupedItems: [[ScannedItemEntity]] = []
    var fetchedResultsController: NSFetchedResultsController<ScannedItemEntity>!
    
    
    // MARK: - FetchRequest and FetchedResultsController Setup
       
    func setupFetchedResultsController() {
           let fetchRequest: NSFetchRequest<ScannedItemEntity> = ScannedItemEntity.fetchRequest()
           
           // Sort the results based on your sorting requirements
           fetchRequest.sortDescriptors = []
           
           fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                 managedObjectContext: context,
                                                                 sectionNameKeyPath: nil,
                                                                 cacheName: nil)
           fetchedResultsController.delegate = self
    

        
           do {
               try fetchedResultsController.performFetch()
           } catch {
               print("Error fetching data: \(error)")
           }
       }
       // MARK: - NSFetchedResultsControllerDelegate methods
       
    
    
    
    /*func fetchItems() -> [ScannedItemEntity] {
        let fetchRequest = NSFetchRequest<ScannedItemEntity>(entityName: "ScannedItemEntity")
        let items = try? context.fetch(fetchRequest)
        return items ?? []
    }*/
    
    // Count all the items
    func groupItemsByCount() -> [String: Int] {
        guard let items = fetchedResultsController.fetchedObjects else {
            return [:]
        }
        
        var itemCounts: [String: Int] = [:]
        
        for item in items {
            if let name = item.name {
                if let count = itemCounts[name] {
                    itemCounts[name] = count + 1
                } else {
                    itemCounts[name] = 1
                }
            }
        }
        
        return itemCounts
    }

    // Group items by category
    func groupItemsByCategory() {
        guard let items = fetchedResultsController.fetchedObjects else {
            return
        }
        
        for item in items {
            let category = item.category ?? "Unknown Category"
            if categories[category] != nil {
                categories[category]!.append(item)
            } else {
                categories[category] = [item]
                categoryNames.append(category)
            }
        }
    }
    
    //group items by name and date
    func groupItemsByNameAndDate() {
        guard let items = fetchedResultsController.fetchedObjects else {
            return
        }
        
        let groupedItemsDictionary = Dictionary(grouping: items) { (item) -> String in
            return "\(item.name):\(item.bestbefore)"
        }
        
        self.groupedItems = Array(groupedItemsDictionary.values)
        self.groupedItems.sort { (group1, group2) -> Bool in
            guard let date1 = group1.first?.bestbefore,
                  let date2 = group2.first?.bestbefore else {
                return false
            }
            return date1 < date2
        }
    }

    func getSoonestsGroupedItems() -> [[ScannedItemEntity]] {
       var soonestDate: Date?

       // Find the soonest date.
       for itemGroup in self.groupedItems {
           if let date = itemGroup.first?.bestbefore {
               if soonestDate == nil {
                   soonestDate = date
               } else if date < soonestDate! {
                   soonestDate = date
               }
           }
       }

       guard let soonest = soonestDate else {
          return []
       }

       // Filter the groups by the soonest date.
       return self.groupedItems.filter { itemGroup in
           guard let dateInGroup = itemGroup.first?.bestbefore else {
               return false
           }

           return dateInGroup == soonest
       }
    }




  
    //update label and category
    func updateLabel() {
        let itemCounts = groupItemsByCount()
        var labelText = "Total items: \(itemCounts.values.reduce(0, +))\n"
        for (name, count) in itemCounts {
            labelText += "\(count) \(name)\n"
        }
  
        itemCountLabelui.text = labelText
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        updateLabel()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: "categoryCell")
        groupItemsByCategory()
        
        groupItemsByNameAndDate()
        itemsTableView.reloadData()

        itemsTableView.dataSource = self
        itemsTableView.delegate = self
        itemsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "itemCell")
        self.itemsTableView.backgroundColor = .clear


    }
    
    
    // MARK: - CollectionView Data Source Methods
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoryNames.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath) as! CustomCollectionViewCell
    cell.textLabel.text = categoryNames[indexPath.row]
    return cell
    }
    
    // MARK: - CollectionView Delegate Methods
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Segue is being triggered")
        performSegue(withIdentifier: "showItems", sender: self)
    }
    
    

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showItemDetails" {
            let destinationVC = segue.destination as! BestBeforeViewController
            if let indexPath = sender as? IndexPath {
                let selectedItem = groupedItems[indexPath.row].first // Assume that groupedItems are populated and the first item exists
                destinationVC.item = selectedItem
            }

        } else if segue.identifier == "showItems" {
            let destinationVC = segue.destination as! ItemsViewController
            if let indexPath = collectionView.indexPathsForSelectedItems?.first {
                let selectedCategory = categoryNames[indexPath.row]
                destinationVC.category = selectedCategory
                destinationVC.items = categories[selectedCategory]!
            }
        }
    }




    private func prepareSegue(for segue: UIStoryboardSegue) {
       let destinationVC = segue.destination as! ItemsViewController
       if let indexPath = collectionView.indexPathsForSelectedItems?.first {
           destinationVC.items = categories[categoryNames[indexPath.row]]!
       }
    }
}
extension StatsPage {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Optionally update or prepare your UI for changes
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
            case .insert, .delete, .update:
                DispatchQueue.main.async {
                    self.updateLabel()
                    self.collectionView.reloadData()
                    self.groupItemsByNameAndDate()
                    self.itemsTableView.reloadData()
                }
            default:
                break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
       // React to completed changes
    }
    
    //date formater
    func formatDateToString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }

    
}

extension StatsPage: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        
        let group = groupedItems[indexPath.row]
        
        if let firstItem = group.first, // safely unwrapping the first item in group
           let itemName = firstItem.name // safely unwrapping name property
        {
            // Safe to use unwrapped itemName and firstItem.bestBefore here
            let bestBeforeDateString = formatDateToString(date: firstItem.bestbefore!)
            let itemCount = group.count
            
            cell.textLabel?.text = "\(itemName) - \(bestBeforeDateString) (\(itemCount) items)"
        }
        let customColor = UIColor(hexString: "#747391")
        cell.backgroundColor = customColor
        return cell
    }

  
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       performSegue(withIdentifier: "showItemDetails", sender: indexPath) //use the correct segue identifier
    }

}






// MARK: - Sizeing for each cell square
/*
private let itemsPerRow: CGFloat = 2 // Two items per row
private let sectionInsets = UIEdgeInsets(top: 5.0,
                                         left: 5.0,
                                         bottom: 5.0,
                                         right: 5.0)


func collectionView(_ collectionView: UICollectionView,
                    layout collectionViewLayout: UICollectionViewLayout,
                    sizeForItemAt indexPath: IndexPath) -> CGSize {
    let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / itemsPerRow

    return CGSize(width: widthPerItem, height: widthPerItem)
}

func collectionView(_ collectionView: UICollectionView,
                    layout collectionViewLayout: UICollectionViewLayout,
                    insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInsets
}

func collectionView(_ collectionView: UICollectionView,
                    layout collectionViewLayout: UICollectionViewLayout,
                    minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
}
*/







/*
import Foundation
import CoreData
import UIKit

class StatsPage: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    @IBOutlet weak var itemCountLabelui: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var categories: [String: [ScannedItemEntity]] = [:]
    var categoryNames: [String] = []
    
    func fetchItems() -> [ScannedItemEntity] {
        let fetchRequest = NSFetchRequest<ScannedItemEntity>(entityName: "ScannedItemEntity")
        let items = try? context.fetch(fetchRequest)
        return items ?? []
    }
    
    //count all the items
    func groupItemsByCount() -> [String: Int] {
        let items = fetchItems()
        var itemCounts: [String: Int] = [:]
  
        for item in items {
            if let name = item.name { // Safely unwrap name
                if let count = itemCounts[name] {
                    itemCounts[name] = count + 1
                } else {
                    itemCounts[name] = 1
                }
            }
        }
  
        return itemCounts
    }
    
    func groupItemsByCategory() {
            let items = fetchItems()
            for item in items {
                let category = item.category ?? "Unknown Category"
                if categories[category] != nil {
                    categories[category]!.append(item)
                } else {
                    categories[category] = [item]
                    categoryNames.append(category)
                }
            }
        }
    
  
    //update label and category
    func updateLabel() {
        let itemCounts = groupItemsByCount()
        var labelText = "Total items: \(itemCounts.values.reduce(0, +))\n"
        for (name, count) in itemCounts {
            labelText += "\(count) \(name)\n"
        }
  
        itemCountLabelui.text = labelText
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabel()
        tableView.dataSource = self
        tableView.delegate = self
        groupItemsByCategory()
    }
    
    
    // MARK: - TableView Data Source Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        cell.textLabel?.text = categoryNames[indexPath.row]
        return cell
    }
    
    // MARK: - TableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Segue is being triggered")
        performSegue(withIdentifier: "showItems", sender: self)
    }
    
    // MARK: - Navigation
       
       override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if segue.identifier == "showItems" {
               prepareSegue(for: segue)
           }
       }

       private func prepareSegue(for segue: UIStoryboardSegue) {
           let destinationVC = segue.destination as! ItemsViewController
           if let indexPath = tableView.indexPathForSelectedRow {
               destinationVC.items = categories[categoryNames[indexPath.row]]!
           }
       }
       
}
*/
