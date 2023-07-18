//
//  StatsPage.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-07-18.
//

import Foundation
import CoreData
import UIKit


class StatsPage: UIViewController {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    @IBOutlet weak var itemCountLabelui: UILabel!
    
    func fetchItems() -> [ScannedItemEntity] {
        let fetchRequest = NSFetchRequest<ScannedItemEntity>(entityName: "ScannedItemEntity")
        let items = try? context.fetch(fetchRequest)
        return items ?? []
    }
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
    }
}




