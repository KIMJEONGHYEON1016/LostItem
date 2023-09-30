//
//  MarkerViewController.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/08/29.
//

import UIKit

class MarkerViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func Information(){
    let storyboard = UIStoryboard(name: "Register", bundle: nil)
    guard let PostViewControllerVC = storyboard.instantiateViewController(withIdentifier: "PostViewController") as? PostViewController else { return }
        present(PostViewControllerVC, animated: true)
    }
}
