//
//  MapMarkerViewController.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/09/10.
//

import UIKit
import NMapsMap
import FirebaseFirestore

class MapMarkerViewController: UIViewController {

    @IBOutlet var subView: NMFNaverMapView!
    
    let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: 37.5666102, lng: 126.9783881))
    var titleLabel = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Location()
        cameraUpdate.animation = .easeIn
        subView.mapView.moveCamera(cameraUpdate)
        subView.showLocationButton = true
        subView.showZoomControls = true
    }
    
    @objc func CompleteButtonTapped() {
        self.saveCenterCoordinates()
        let storyboard = UIStoryboard(name: "Register", bundle: nil)
        guard let RegisterInfoViewControllerVC = storyboard.instantiateViewController(withIdentifier: "RegisterInfoViewController") as? RegisterInfoViewController else { return }
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(RegisterInfoViewControllerVC, animated: false)
    }
    
    @objc func BackButtonTapped() {
           // Back 버튼을 눌렀을 때 MainVC를 dismiss
           self.dismiss(animated: true, completion: nil)
       }
    
    func Location() {
     
        let imageView = UIImageView(image: UIImage(named: "free-icon-lost-items-3372390-3.png"))
            imageView.frame = CGRect(x: (view.bounds.width - 20) / 2, y: (view.bounds.height - 115) / 2, width: 30, height: 30)
            imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        var BackButton: UIButton!

        BackButton = UIButton(type: .system)
        BackButton.setTitle("Back", for: .normal)
        BackButton.frame = CGRect(x: 10, y: 20, width: 60, height: 30)
        if let backImage = UIImage(named: "free-icon-back-arrow-594830.png") {
               BackButton.setImage(backImage, for: .normal)
               BackButton.imageView?.contentMode = .scaleAspectFit // 이미지를 버튼 크기에 맞춥니다.
           }
        BackButton.addTarget(self, action: #selector(BackButtonTapped), for: .touchUpInside)
        view.addSubview(BackButton)
        
        var CompleteButton: UIButton!

        CompleteButton = UIButton(type: .system)
        CompleteButton.setTitle("Complete", for: .normal)
        CompleteButton.frame = CGRect(x: 155, y: 650, width: 80, height: 30)
        CompleteButton.backgroundColor = .black
        CompleteButton.addTarget(self, action: #selector(CompleteButtonTapped), for: .touchUpInside)
        view.addSubview(CompleteButton)
        
        
        
    }
    
    func saveCenterCoordinates() {
        if let subView = subView { // subView 변수가 올바른지 확인
            let centerX = subView.frame.width / 2
            let centerY = subView.frame.height / 2
            
            // 중앙 좌표를 화면 좌표부터 지도 좌표로 변환합니다.
            let centerLatLng = subView.mapView.projection.latlng(from: CGPoint(x: centerX, y: centerY))
            
            // Firestore 데이터베이스에 접근합니다.
            let db = Firestore.firestore()
            
            // "게시글" 컬렉션에 좌표를 저장합니다.
            let data: [String: Any] = [
                "latitude": centerLatLng.lat,
                "longitude": centerLatLng.lng
                // 다른 필요한 데이터도 함께 저장할 수 있습니다.
            ]
            
            let collectionRef = db.collection("게시글")
            
            let documentRef = collectionRef.document(self.titleLabel)
            documentRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    // 문서가 존재하면 업데이트 작업 수행
                    documentRef.updateData(data) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document updated")
                        }
                    }
                }
            }
        }
    }
}
