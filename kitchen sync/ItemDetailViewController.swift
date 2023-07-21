//
//  ItemDetailViewController.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-07-21.
//

import Foundation
import UIKit
import CoreData

protocol ItemDetailViewControllerDelegate: AnyObject {
    func didDeleteItem()
}

class ItemDetailViewController: UIViewController {
weak var delegate: ItemDetailViewControllerDelegate?


    // UIview behind displayView
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var displayView: UIView!
    
    var id: String?
    var name: String?
    var category: String?
    var bestBeforeDate: Date?
    
    var selectedIndexPath: IndexPath?
    
    // Create an instance of ViewController
    let viewController = ViewController()
    
    // Outlets for your labels
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var bestBeforeLabel: UILabel!

    // Outlet for the exit button
    @IBOutlet weak var exitButton: UIButton!
    
    //Delete item button
    @IBOutlet weak var deleteButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
           
        // Make the background color transparent
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        // Set up the delete button
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
           
        // Set up the exit button
        exitButton.addTarget(self, action: #selector(exitButtonTapped), for: .touchUpInside)
        
           
        //Set up the tap outside exit
        // Adding the tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        contentView.addGestureRecognizer(tapGesture)

        // Update the item details
        updateDetails()
    }
    
    
    //Tap outside displayView and it exit
    @objc func handleTap(sender: UITapGestureRecognizer) {
        let location = sender.location(in: contentView)
        
        // If the tap was not on detailView
        if displayView.frame.contains(location) == false {
            dismiss(animated: true)
        }
    }

    @objc func exitButtonTapped() {
        print("exit button tapped")
        self.dismiss(animated: true, completion: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Dismiss this view controller when the area outside of content view is tapped
        if !contentView.frame.contains(touches.first!.location(in: self.view)) {
               self.dismiss(animated: true, completion: nil)
        }
    }
       
    func updateDetails() {
        idLabel.text = id
        nameLabel.text = name
        categoryLabel.text = category
        if let bestBeforeDate = bestBeforeDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            bestBeforeLabel.text = formatter.string(from: bestBeforeDate)
        }
    }
    
    /*
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        guard let id = idLabel.text else {
            print("ID is nil")
            return
        }
        do {
            try viewController.deleteItem(scanId: id)
        } catch {
            print("Error deleting item: \(error)")
        }
    }

     */
     
     
    //delete item function from ViewCOntroller
    @objc func deleteButtonTapped() {
        print("delete button pressed")
        guard let id = idLabel.text else {
            print("ID is nil")
            return
        }
        
        viewController.deleteItem(scanId: id)
        
        // Notify the delegate that an item has been deleted
        delegate?.didDeleteItem()
                
        self.dismiss(animated: true, completion: nil)
            }
        
    
        
   }
