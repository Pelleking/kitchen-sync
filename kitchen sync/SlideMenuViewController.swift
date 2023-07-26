//
//  SlideMenuViewController.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-07-26.
//

import Foundation
import UIKit


class SlideMenuViewController: UIViewController  {
    
    @IBAction func XBUtton(_ sender: Any) {
        
        parent?.performSelector(onMainThread: #selector(ViewController.closeMenu), with: nil, waitUntilDone: false)
        
    }
    
    @IBAction func menuButtonStats(_ sender: Any) {
        parent?.performSelector(onMainThread: #selector(ViewController.closeMenu), with: nil, waitUntilDone: false)
        
        // call method to close the menu
        (parent as? ViewController)?.closeMenu()
        
    }
    
    
    @IBAction func menuButtonClicked(_ sender: UIButton) {
        // perform button's action

        // call method to close the menu
        parent?.performSelector(onMainThread: #selector(ViewController.closeMenu), with: nil, waitUntilDone: false)
        
        // call method to close the menu
        (parent as? ViewController)?.closeMenu()
    }

    
}
