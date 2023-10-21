//
//  ViewController.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/08/08.
//

import Foundation
import NMapsMap
import FirebaseFirestore

class ViewController: UIViewController {
    
    @IBOutlet var subView: NMFNaverMapView!
    @IBOutlet var refreshBtn: UIButton!
    
    let infoWindow = NMFInfoWindow()
    let marker = NMFMarker()
    let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: 37.5666102, lng: 126.9783881))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //카메라 이동
        fetchMarkersFromFirestore()
        cameraUpdate.animation = .easeIn
        subView.mapView.moveCamera(cameraUpdate)
        subView.showLocationButton = true
        subView.showZoomControls = true
        subView.mapView.positionMode = .direction
        subView.mapView.logoAlign = .rightTop
        TabBarItem()
        refreshBtn.layer.cornerRadius = 0.5 * refreshBtn.bounds.size.width

    }
    
    //새로고침 버튼
    @IBAction func refreshButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "TabBar", bundle: nil)
        guard let TabBarControllerVC = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController else { return }
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(TabBarControllerVC, animated: false)
    }
    
    //탭바 아이템 글씨 색상
    func TabBarItem() {
      
        let appearance = UITabBarAppearance()
            
            // 타이틀의 일반 상태 (선택되지 않은 상태) 색상 설정
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.darkGray] // 원하는 색상으로 변경
            
            // 타이틀의 선택된 상태 색상 설정
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black] // 원하는 색상으로 변경
        UITabBar.appearance().standardAppearance = appearance
    }
    
    // Firestore에서 "게시글" 컬렉션의 문서를 가져와서 좌표 데이터 필드를 네이버지도의 마커로 표시
    func fetchMarkersFromFirestore() {
        let db = Firestore.firestore()
        let collectionRef = db.collection("게시글")
        
        collectionRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found.")
                return
            }
            
            // 각 문서에서 좌표 데이터 필드를 추출하고 네이버지도의 마커로 표시
            for document in documents {
                let data = document.data()
                
                if let latitude = data["latitude"] as? Double,
                   let longitude = data["longitude"] as? Double {
                    // 좌표를 이용하여 네이버지도의 마커를 생성하고 추가
                    let marker = NMFMarker()
                    marker.position = NMGLatLng(lat: latitude, lng: longitude)
                    marker.mapView = self.subView.mapView
                    
                    //마커 이미지 및 크기 지정
                    marker.iconImage = NMFOverlayImage(name: "lost item.png")
                    marker.width = 30
                    marker.height = 30
                    
                    let storyboard = UIStoryboard(name: "Register", bundle: nil)
                    guard let PostViewControllerVC = storyboard.instantiateViewController(withIdentifier: "PostViewController") as? PostViewController else { return }
                    
                    // 마커를 탭할시 정보창 보여줌
                    let handler = { [weak self] (overlay: NMFOverlay) -> Bool in
                        if let marker = overlay as? NMFMarker {
                            // 현재 마커에 정보 창이 열려있지 않을 경우 엶
                            PostViewControllerVC.latitude = marker.position.lat
                            PostViewControllerVC.longitude = marker.position.lng
                            self?.present(PostViewControllerVC, animated: true)
                            PostViewControllerVC.deleteBtn.isHidden = true
                            PostViewControllerVC.ChatButton.isHidden = false
                            let db  =  Firestore.firestore()
                            db.collection("게시글")
                                .whereField("latitude", isEqualTo: latitude)
                                .whereField("longitude", isEqualTo: longitude)
                                .getDocuments { (querySnapshot, error) in
                                    if let error = error {
                                        print("Error fetching documents: \(error)")
                                        return
                                    }
                                    
                                    if let document = querySnapshot?.documents.first {
                                        // 문서가 존재하면 필드 값을 가져와 화면에 표시
                                        let documentID = document.documentID
                                        PostViewControllerVC.titleLabel.text = documentID
                                        if let chatuser = document["유저"] as? String {
                                            if chatuser == UserDefaults.standard.string(forKey: "UserEmailKey")! {
                                                PostViewControllerVC.deleteBtn.isHidden = false
                                                PostViewControllerVC.ChatButton.isHidden = true
                                            } else {
                                                PostViewControllerVC.chatUser = chatuser
                                            }
                                        }
                                    }
                                }
                        }
                        return true
                    };
                    
                    marker.touchHandler = handler
                    
                }
            }
        }
    }
    
  

}

