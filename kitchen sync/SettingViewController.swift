//
//  SettingViewController.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-07-27.
//

import Foundation
import UIKit
import CoreData

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var data: [CategoryDatan] = []
    var context: NSManagedObjectContext!
    
    func updateData(newData: [CategoryDatan]) {
        self.data = newData
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CategoryCell.self, forCellReuseIdentifier: "cell")
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CategoryDatan")
        do {
            let result = try context.fetch(request)
        for data in result as! [NSManagedObject] {
            if let categoryDatan = data as? CategoryDatan {
                print(categoryDatan.name!)  // Access the 'name' attribute
                if categoryDatan.isEditable != false {  // Only exclude the category from the 'data' array if 'isEditable' is explicitly set to false
                    self.data.append(categoryDatan)  // Add the fetched object to the 'data' array
                    print("printing with filter \(String(describing: categoryDatan.name))")
                }
            }
        }
        } catch {
            print("Failed to fetch categories")
        }
        
        checkForDefaultCategories()
    }
    
    //Custom category Cell
    class CategoryCell: UITableViewCell {
        let textField: UITextField = {
            let textField = UITextField()
            textField.translatesAutoresizingMaskIntoConstraints = false
            return textField
        }()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupTextField()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupTextField()
        }
        
        private func setupTextField() {
            contentView.addSubview(textField)
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                textField.topAnchor.constraint(equalTo: contentView.topAnchor),
                textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(data.count)
        return data.count
    }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CategoryCell
            // Get the category for this row
            let category = data[indexPath.row]
            cell.textField.text = category.name
            print("categoryname \(category.name!)")
            cell.textField.tag = indexPath.row  // Keeping track of which index the textField relates to
            cell.textField.delegate = self
            cell.textField.isUserInteractionEnabled = category.isEditable // Disable the textField if the category isn't editable
            
            return cell
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            let index = textField.tag
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CategoryDatan")
            do {
                let result = try context.fetch(request)
                let category = result[index] as! NSManagedObject as! CategoryDatan
                category.name = textField.text
                category.setValue(textField.text ?? "", forKey: "name")
                try context.save()
            } catch {
                print("Failed to update category")
            }
            tableView.reloadData()  // Refresh tableView
        }
        
        //dismiss keyboard
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
        
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                // Delete the category from the data array
                let categoryToDelete: CategoryDatan = data[indexPath.row]
                let category = data[indexPath.row]
                //check if the is deleteble
                if category.isEditable {
                    data.remove(at: indexPath.row)
                    
                    // Delete the category from the CoreData
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CategoryDatan")
                    do {
                        let result = try context.fetch(request)
                        for category in result as! [NSManagedObject] {
                            if category === categoryToDelete {
                                context.delete(category)
                                try context.save()
                                break
                            }
                        }
                    } catch {
                        print("Failed to delete category")
                    }
                    
                    // Delete the row from the table view
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        }
        
        @IBAction func addButtonTapped(_ sender: Any) {
            let alert = UIAlertController(title: "Add Category", message: nil, preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "Category Name"
            }
            let addAction = UIAlertAction(title: "Add", style: .default) { (_) in
                guard let categoryName = alert.textFields?.first?.text, !categoryName.isEmpty else { return }
                
                
                let newCategory = CategoryDatan(context: self.context)
                newCategory.name = categoryName
                newCategory.isEditable = true
                // Add the category to the data array
                self.data.append(newCategory)
                
                do {
                    try self.context.save()
                } catch {
                    print("Failed to save new category")
                }
                
                // Reload the table view
                self.tableView.reloadData()
            }
            alert.addAction(addAction)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        }
        
        func checkForDefaultCategories() {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CategoryDatan")
            do {
                let result = try context.fetch(request)
                if result.isEmpty {
                    // No categories exist, so add the default values
                    let defaultCategories = ["Tech", "Groceries", "Cleaning"]
                    // Add "Category" first
                    let categoryNonEditable = CategoryDatan(context: context)
                    categoryNonEditable.name = "Category"
                    categoryNonEditable.isEditable = false // This one won't be editable
                    // Then add the rest of the categories
                    for category in defaultCategories {
                        let newCategoryEditable = CategoryDatan(context: context)
                        newCategoryEditable.name = category
                        newCategoryEditable.isEditable = true // These ones will be editable
                    }
                    // Save the context to persist the new categories
                    try context.save()
                    tableView.reloadData()  // Refresh tableView
                    print("default loaded")
                }
            } catch {
                // Handle any errors
                print("Failed to fetch categories: \(error)")
            }
        }
        
}

