//
//  ChatViewController.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/08/17.
//

import Foundation
import FirebaseFirestore

class ChatViewController: UIViewController {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var chattingtable: UITableView?
    
    var user1ValuesCount: Int = 0
    var user1Values: [String] = [] // user1의 이메일을 저장할 배열
    var user2Values: [String] = [] // user2의 이메일을 저장할 배열
    var nickName: String?
    var profileImage: UIImage?
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        chattingtable?.dataSource = self
        chattingtable?.delegate = self
        searchBar?.delegate = self
        loadDataFromFirestore() // Firestore에서 데이터를 가져오는 함수 호출
        TabBarItem()
    }
    
    
    func TabBarItem() {
        let appearance = UITabBarAppearance()
            
            // 타이틀의 일반 상태 (선택되지 않은 상태) 색상 설정
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.darkGray] // 원하는 색상으로 변경
            
            // 타이틀의 선택된 상태 색상 설정
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemBlue] // 원하는 색상으로 변경
        UITabBar.appearance().standardAppearance = appearance
    }
    
    // Firestore에서 데이터를 가져오는 함수
    func loadDataFromFirestore() {
        let currentUserEmail = UserDefaults.standard.string(forKey: "UserEmailKey") ?? ""
        let db = Firestore.firestore()
        db.collection("채팅")
            .whereField("user1", isEqualTo: currentUserEmail) // user1인 경우
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("채팅 문서를 가져오는 데 실패했습니다: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("채팅 문서가 없습니다.")
                    return
                }
                
                // Firestore에서 가져온 데이터를 user1Values 배열에 저장
                self.user1Values = documents.compactMap { document in
                    if let data = document.data() as? [String: Any],
                       let user2 = data["user2"] as? String {
                        
                        return user2
                    }
                    return nil
                }
                
                // 테이블 뷰를 업데이트합니다.
                self.chattingtable?.reloadData()
            }
        
        db.collection("채팅")
            .whereField("user2", isEqualTo: currentUserEmail) // user2인 경우
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("채팅 문서를 가져오는 데 실패했습니다: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("채팅 문서가 없습니다.")
                    return
                }
                
                // Firestore에서 가져온 데이터를 user2Values 배열에 저장
                self.user2Values = documents.compactMap { document in
                    if let data = document.data() as? [String: Any],
                       let user1 = data["user1"] as? String {
                        
                        return user1
                    }
                    return nil
                }
                
                // 테이블 뷰를 업데이트합니다.
                self.chattingtable?.reloadData()
            }
    }
}

// UITableViewDelegate 및 UITableViewDataSource 프로토콜 구현
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // user1Values와 user2Values 배열의 합계를 반환하여 셀의 총 개수를 설정
        return user1Values.count + user2Values.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatTableCell", for: indexPath) as! ChatTableCell
        
        // 기본 이미지 설정
        if cell.profileImage?.image == nil {
            cell.profileImage?.image = UIImage(named: "free-icon-user-7718888.png")
        }
        cell.profileImage?.layer.cornerRadius = cell.profileImage.frame.size.width / 2
        cell.profileImage?.clipsToBounds = true
        cell.profileImage?.contentMode = .scaleAspectFill
        
        var user: String = ""
        
        // indexPath.row를 사용하여 필요한 데이터를 가져옵니다.
        if indexPath.row < user1Values.count {
            user = user1Values[indexPath.row]
        } else if indexPath.row < (user1Values.count + user2Values.count) {
            let user2Index = indexPath.row - user1Values.count
            user = user2Values[user2Index]
        }
        
        let db = Firestore.firestore()
        
        db.collection("Users").document(user).getDocument { (document, error) in
            if let error = error {
                print("사용자의 닉네임을 가져오는 데 실패했습니다: \(error.localizedDescription)")
            } else {
                if let document = document, let nickName = document["닉네임"] as? String {
                    // 사용자의 닉네임을 설정합니다.
                    DispatchQueue.main.async {
                        cell.nickName.text = nickName
                        self.nickName = nickName
                    }
                }
                if let document = document, let profileImage = document["프로필 사진"] as? String,
                   let profileImageURL = URL(string: profileImage) {
                    print("Document data: \(profileImageURL)")
                    
                    // 이미지 다운로드 및 표시
                    URLSession.shared.dataTask(with: profileImageURL) { (data, response, error) in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                cell.profileImage.image = image
                                self.profileImage = image
                            }
                        }
                    }.resume()
                }
            }
        }
        return cell
    }
    
    //셀 클릭시 채팅방으로 이동
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        guard let ChatRoomViewControllerVC = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as? ChatRoomViewController else { return }
        
        var chatUser: String = ""
        
        if indexPath.row < user1Values.count {
            chatUser = user1Values[indexPath.row]
        } else if indexPath.row < (user1Values.count + user2Values.count) {
            let user2Index = indexPath.row - user1Values.count
            chatUser = user2Values[user2Index]
        } else {
            // 유효한 인덱스 범위를 벗어난 경우 오류 처리
            print("Invalid indexPath")
            return
        }
        
        ChatRoomViewControllerVC.chatUser = chatUser
        ChatRoomViewControllerVC.nickName = self.nickName
        ChatRoomViewControllerVC.profileImage = self.profileImage
        ChatRoomViewControllerVC.modalPresentationStyle = .fullScreen
        present(ChatRoomViewControllerVC, animated: true)
    }
}

// 서치바
extension ChatViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // 서치바 검색 기능 구현
    }
}
