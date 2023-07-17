//
//  AddingNewItem.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-06-03.
//

import UIKit    
import Firebase

class AddingNewItem: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var datepickerbestbefore: UIDatePicker!
    @IBOutlet weak var Itemnameinput: UITextField!
    @IBOutlet weak var Itemiddisplay: UILabel!
    @IBOutlet weak var UICategorypicker: UIPickerView!
    
    let data = ["Category", "tech", "grocceris"]

    override func viewDidLoad() {
        super.viewDidLoad()
        UICategorypicker.dataSource = self
        UICategorypicker.delegate = self
        Itemnameinput.delegate = self
        
        // Set the default value of the UIPickerView
        UICategorypicker.selectRow(0, inComponent: 0, animated: false)
    }
   
    //dismisses the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func showScannerNewItem(_ sender: UIButton) {
        let scanner = ScanningNewItem()
        scanner.delegate = self
        present(scanner, animated: true, completion: nil)
    }
    
    
    //check if all the fields is filled
    func checkAllUIElementsFilled() -> Bool {
        // Check if the UITextField is empty
        guard let itemName = Itemnameinput.text, !itemName.isEmpty else { return false }
    //    guard let bestBeforeDate = bestbeforedatenum.text, !bestBeforeDate.isEmpty else { return false }
        
        // Check if the UIPickerView has a selected row
        let selectedRow = UICategorypicker.selectedRow(inComponent: 0)
        if selectedRow == 0 {
            return false
        }
        
        // Check if the UIDatePicker has a selected date
        let currentDate = Date()
        if datepickerbestbefore.date.compare(currentDate) == .orderedAscending {
            return false
        }
        
        // Check if the UILabel is empty
        guard let itemId = Itemiddisplay.text, !itemId.isEmpty else { return false }
        
        return true
    }

    
    @IBAction func additemstodatabase(_ sender: UIButton) {
        if !checkAllUIElementsFilled() {
            // Show an error message to the user
            let alert = UIAlertController(title: "Error", message: "Please fill in all fields", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        // Get the selected date from datepickerbestbefore and format it as a string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let bestBeforeDateString = dateFormatter.string(from: datepickerbestbefore.date)

        
        // Get the selected row of the UIPickerView
        let selectedRow = UICategorypicker.selectedRow(inComponent: 0)
        
        // Get the text of the UITextField and UILabel elements
        guard let itemName = Itemnameinput.text, !itemName.isEmpty else { return }
     //   guard let bestBeforeDate = bestbeforedatenum.text, !bestBeforeDate.isEmpty else { return }
        guard let category = data[safe: selectedRow] else { return }
        guard let itemId = Itemiddisplay.text, !itemId.isEmpty else { return }

        // Write the values to the database
        let ref = Database.database(url:"https://kitchen-sync-1-5c7b4-default-rtdb.europe-west1.firebasedatabase.app").reference()
        let productsRef = ref.child("products")
        let itemRef = productsRef.child(itemId)
        itemRef.setValue([
            "name": itemName,
            "best-before": bestBeforeDateString,
            "category": category,
            // Add more to the database if I need
        ])
        
        // Show a success message
        let alert = UIAlertController(title: "Success", message: "Item added to database", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Perfect", style: .default) { (action) in
            // Go back to the previous UIViewController after the user presses the "OK" button
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)

        
       
        // Print the values to the console
        print("Item name: \(itemName)")
        print("Best before date: \(bestBeforeDateString)")
        print("Category: \(category)")
        print("Item ID: \(itemId)")
        
        
    }

    
    
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


extension AddingNewItem: ScanningNewItemDelegate {
    func didScanItem(_ item: NewItemID) {
        Itemiddisplay.text = item.id
    }
}

//Category picker datasource
extension AddingNewItem: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView (_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.count
    }
    
}

//category picker delegate
extension AddingNewItem: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data[row]
    }
    
}

protocol ScanningNewItemDelegate: AnyObject {
    func didScanItem(_ item: NewItemID)
}

struct NewItemID {
    let id: String
}
