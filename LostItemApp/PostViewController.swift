//
//  PostViewController.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/08/31.
//

import UIKit
import Firebase
import FirebaseFirestore


class PostViewController: UIViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var image1: UIImageView!
    @IBOutlet var image2: UIImageView!
    @IBOutlet var image3: UIImageView!
    @IBOutlet var mainText: UITextView!
    @IBOutlet var deleteBtn: UIButton!
    
    var ChatButton: UIButton!
    var documentID: String?
    let db = Firestore.firestore()
    var latitude: Double?
    var longitude: Double?
    var chatUser: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.latitude != nil {
            self.fetchDataUsingCoordinates(latitude: self.latitude!, longitude: self.longitude!)
        } else {
            self.UploadData()
        }
        ChatButtonItem()
        
        mainText.layer.borderWidth = 1.0
        // 테두리 색상 설정
        mainText.layer.borderColor = UIColor.lightGray.cgColor
        mainText.isEditable = false
    }
    
    @IBAction func BackBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func DeleteBtn(_ sender: Any) {
            //알림창 생성
            let alertController = UIAlertController(title: "삭제 확인", message: "정말로 삭제하실건가요?", preferredStyle: .alert)
            
            //"네" 버튼 추가
            let yesAction = UIAlertAction(title: "네", style: .destructive) { (action) in
                // "네" 버튼을 눌렀을 때의 로직을 여기에 추가
                self.DeleteDocument()
                self.dismiss(animated: true)
            }
            
            //"아니오" 버튼 추가
            let noAction = UIAlertAction(title: "아니오", style: .cancel, handler: nil)
            
            //알림창에 버튼 추가
            alertController.addAction(yesAction)
            alertController.addAction(noAction)
            
            //알림창 표시
            present(alertController, animated: true, completion: nil)
    }
    
    func DeleteDocument() {
        let db = Firestore.firestore()
        
        // 컬렉션에 대한 참조 생성
        let collectionRef = db.collection("게시글")
        
        
        collectionRef.whereField("유저", isEqualTo: UserDefaults.standard.string(forKey: "UserEmailKey") ?? "")
                     .whereField("내용", isEqualTo: mainText.text ?? "")
                     .getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            
            if let documents = snapshot?.documents {
                for document in documents {
                    // 해당 문서를 삭제
                    document.reference.delete { error in
                        if let error = error {
                            print("Error deleting document: \(error)")
                        } else {
                            print("Document successfully deleted")
                        }
                    }
                }
            }
        }
    }
    func UploadData() {
        if let documentID = documentID {
            // Firestore에서 문서를 가져오기 위해 documentID를 사용
            let docRef = db.collection("게시글").document(documentID)
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    // 문서가 존재하면 필드 값을 가져와 화면에 표시
                    
                    // document ID를 titleLabel에 표시
                    self.titleLabel.text = documentID
                    
                    // "내용" 필드의 내용을 mainText에 표시
                    if let mainText = document["내용"] as? String {
                        self.mainText.text = mainText
                    }
                    // "분실물 사진" 배열의 URL을 가져와 이미지를 표시
                    if let photoLinks = document["분실물 사진"] as? [String] {
                        if photoLinks.indices.contains(0) {
                            self.loadImage(from: photoLinks[0], into: self.image1)
                        }
                        if photoLinks.indices.contains(1) {
                            self.loadImage(from: photoLinks[1], into: self.image2)
                        }
                        if photoLinks.indices.contains(2) {
                            self.loadImage(from: photoLinks[2], into: self.image3)
                        }
                    } else {
                        print("Document does not exist")
                    }
                }
            }
        }
    }
    
    func fetchDataUsingCoordinates(latitude: Double, longitude: Double) {
        // 파이어스토어에서 위도와 경도를 사용하여 문서를 쿼리
        let db = Firestore.firestore()
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
                    self.titleLabel.text = documentID
                    if let mainText = document["내용"] as? String {
                        self.mainText.text = mainText
                    }
                    
                    if let photoLinks = document["분실물 사진"] as? [String] {
                        if photoLinks.indices.contains(0) {
                            self.loadImage(from: photoLinks[0], into: self.image1!)
                        }
                        if photoLinks.indices.contains(1) {
                            self.loadImage(from: photoLinks[1], into: self.image2!)
                        }
                        if photoLinks.indices.contains(2) {
                            self.loadImage(from: photoLinks[2], into: self.image3!)
                        }
                    }
                } else {
                    print("Document does not exist")
                }
            }
    }
    
    func loadImage(from urlString: String, into imageView: UIImageView) {
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error downloading image: \(error)")
                } else if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.contentMode = .scaleAspectFill
                        imageView.image = image
                        print("Success downloading image: \(url)")
                        
                    }
                }
            }.resume()
        }
    }
    
    func ChatButtonItem() {
        
        ChatButton = UIButton(type: .system)
        ChatButton.setTitle("채팅", for: .normal)
        ChatButton.frame = CGRect(x: 155, y: 700, width: 80, height: 30)
        ChatButton.backgroundColor = .black
        ChatButton.addTarget(self, action: #selector(ChatButtonTapped), for: .touchUpInside)
        view.addSubview(ChatButton)
        ChatButton.isHidden = true
        
    }
    
    @objc func ChatButtonTapped() {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        guard let ChatRoomViewControllerVC = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as? ChatRoomViewController else { return }
        
        // Firestore 데이터베이스에 대한 참조
        let db = Firestore.firestore()
        
        // "채팅" 컬렉션 내에 문서를 생성
        let userEmail = UserDefaults.standard.string(forKey: "UserEmailKey") ?? ""
        let chatDocumentID = userEmail + "&" + chatUser!
        let documentPath = chatUser! + "&" + userEmail// "your_collection_name"은 컬렉션 이름

        // Firestore에 접근하여 document 존재 여부 확인
        db.collection("채팅").document(documentPath).getDocument { (document, error) in
            if let error = error {
                print("Error getting document: \(error)")
            } else if let document = document, document.exists {
                // 해당 document가 존재하는 경우
                print("Document exists: \(document.data() ?? [:])")
                
                // document에서 "user1" 필드의 값을 가져와서 self.chatUser에 할당
                if let user1 = document.data()?["user1"] as? String {
                    self.chatUser = user1
                    print("self.chatUser에 할당된 값: \(self.chatUser ?? "")")
                }
            } else {
                // 해당 document가 존재하지 않는 경우
                db.collection("채팅").document(chatDocumentID).setData([
                    "user1": userEmail, // 사용자 1의 이메일
                    "user2": self.chatUser!, // 사용자 2의 이메일
                ]) { error in
                    if let error = error {
                        print("채팅 문서를 생성하는 데 실패했습니다: \(error.localizedDescription)")
                        return
                    }
                    
                    print("채팅 문서를 성공적으로 생성했습니다.")
                }
            }
        }
        // "채팅" 컬렉션 내에 문서를 생성하고 필요한 데이터를 추가
       
    
        ChatRoomViewControllerVC.chatUser = chatUser
        present(ChatRoomViewControllerVC, animated: true)
    }
}


