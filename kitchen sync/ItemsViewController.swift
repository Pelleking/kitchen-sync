//
//  ItemsViewController.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-07-19.
//

import Foundation
import UIKit
import CoreData

class ItemsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var items: [ScannedItemEntity] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ItemsViewController loaded")
        tableView.dataSource = self
        tableView.delegate = self
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
        // Perform segue to item detail view or directly allow editing / deletion
    }
    
    
}
