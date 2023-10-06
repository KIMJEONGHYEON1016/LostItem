//
//  RegisterViewController.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/08/26.
//

    import UIKit
    import Foundation
    import Firebase
    import FirebaseFirestore

    class RegisterViewController: UIViewController {
        
        let db = Firestore.firestore()
        var ref: DocumentReference?
        var numberOfCells = 0
        var cellDataCache: [IndexPath: UIImage] = [:]

        @IBOutlet var mainTableView: UITableView!
    
        
        override func viewDidLoad() {
            super.viewDidLoad()
            mainTableView?.dataSource = self
            mainTableView?.delegate = self
            let customColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
            mainTableView?.layer.borderWidth = 1.0
            mainTableView?.layer.borderColor = customColor.cgColor
            mainTableView?.layer.cornerRadius = 3.0
            mainTableView?.reloadData()
        }
        
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            mainTableView?.reloadData()
        }
        
        @IBAction func RefreshBtn(_ sender: Any) {
            mainTableView?.reloadData()
        }
        
        @IBAction func BackBtn(_ sender: Any) {
            self.dismiss(animated: true)
        }
    }
        
        
    extension RegisterViewController: UITableViewDelegate, UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            let docRef = db.collection("게시글")
                .whereField("유저", isEqualTo: UserDefaults.standard.string(forKey: "UserEmailKey")!)
            
            docRef.getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    self.numberOfCells = querySnapshot?.documents.count ?? 0
                }
            }
            
            return numberOfCells
        }
        
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // 선택한 셀의 titleLabel 텍스트를 가져오기
            guard let cell = tableView.cellForRow(at: indexPath) as? RegisterTableViewCell else {
                return
            }
            let selectedTitle = cell.previewLabel.text ?? ""
            
            // Firestore에서 해당 titleLabel와 같은 값을 가진 문서 ID를 찾기
            let docRef = db.collection("게시글")
                .whereField("유저", isEqualTo: UserDefaults.standard.string(forKey: "UserEmailKey")!)
            
            docRef.getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    let documents = querySnapshot?.documents ?? []
                    if let document = documents.first(where: { $0.documentID == selectedTitle }) {
                        // 선택한 셀과 일치하는 문서 ID를 찾은후
                        let documentID = document.documentID
                        
                        // PostViewController로 이동하면서 문서 ID를 전달
                        if let postVC = self.storyboard?.instantiateViewController(withIdentifier: "PostViewController") as? PostViewController {
                            postVC.documentID = documentID
                            self.present(postVC, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
        
        
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RegisterTableViewCell", for: indexPath) as! RegisterTableViewCell
            cell.previewImage.contentMode = .scaleAspectFill
            
            let docRef = db.collection("게시글")
                .whereField("유저", isEqualTo: UserDefaults.standard.string(forKey: "UserEmailKey")!)
            
            
            
            docRef.getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    let documents = querySnapshot?.documents ?? []
                    if indexPath.row < documents.count {
                        let document = documents[indexPath.row]
                        
                        // Set the document ID as the cell's text
                        DispatchQueue.main.async {
                            cell.previewLabel.text = document.documentID
                        }
                        
                      if let messageDateTimestamp = document["date"] as? Double {
                            
                            // Timestamp를 Date로 변환
                            let messageDate = Date(timeIntervalSince1970: messageDateTimestamp)
                                                    
                            // 현재 날짜와 시간 가져오기
                            let currentDate = Date()
                            
                            // 메시지 날짜와 현재 날짜를 비교
                            let calendar = Calendar.current
                            let messageDateComponents = calendar.dateComponents([.year, .month, .day], from: messageDate)
                            let currentDateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                            
                            let dateFormatter = DateFormatter()
                            
                            if messageDateComponents.year == currentDateComponents.year {
                                // 같은 해에 속하는 경우
                                if messageDateComponents.month == currentDateComponents.month && messageDateComponents.day == currentDateComponents.day {
                                    // 오늘인 경우
                                    dateFormatter.dateFormat = "HH:mm"
                                } else {
                                    // 이번 년도에 속하지만 오늘이 아닌 경우
                                    dateFormatter.dateFormat = "MM월 dd일"
                                }
                            } else {
                                // 다른 년도에 속하는 경우
                                dateFormatter.dateFormat = "YYYY년 MM월 dd일"
                            }
                            
                            let formattedDate = dateFormatter.string(from: messageDate)
                            
                            cell.previewDate.text = formattedDate
                        }
                        if let previewImages = document["분실물 사진"] as? [String], let firstImageURLString = previewImages.first, let previewImageImageURL = URL(string: firstImageURLString) {
                            print("Document data: \(previewImageImageURL)")
                            
                            // 이미지 다운로드 및 표시
                            URLSession.shared.dataTask(with: previewImageImageURL) { (data, response, error) in
                                if let data = data, let image = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        cell.previewImage.image = image
                                    }
                                }
                            }.resume()
                        }
                    }
                }
            }
                return cell
        }
}

