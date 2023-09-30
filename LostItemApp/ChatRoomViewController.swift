//
//  ChatRoomViewController.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/08/23.
//

import Foundation
import FirebaseFirestore
import UITextView_Placeholder


class ChatRoomViewController: UIViewController {
    
    @IBOutlet var chattingRoom: UITableView!
    
    @IBOutlet var messageTextField: UITextView!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    var chatUser: String?
    var nickName: String?
    var profileImage: UIImage?
    
    struct Message {
        let sender: String
        let body: String
    }
    
    @IBAction func BackBtn(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        guard let ChatViewControllerVC = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController else { return }
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(ChatViewControllerVC, animated: true)
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        if let messageBody = messageTextField.text, let messageSender = UserDefaults.standard.string(forKey: "UserEmailKey"), let chatUser = chatUser {
            
            // 사용자 이메일과 채팅 사용자 이메일을 정렬후 합침
            let sortedEmails = [messageSender, chatUser].sorted()
            let chatDocumentID = sortedEmails[0] + "&" + sortedEmails[1]
            
            // "채팅" 컬렉션 내의 문서 참조 획득
            let chatDocumentReference = db.collection("채팅").document(chatDocumentID)
            
            // "메시지" 서브컬렉션에 새로운 메시지를 추가
            chatDocumentReference.collection("메시지").addDocument(data: [
                "sender": messageSender,
                "body": messageBody,
                "date": Date().timeIntervalSince1970
            ]) { (error) in
                if let e = error {
                    print("메시지를 서브컬렉션에 추가하는 데 실패했습니다: \(e.localizedDescription)")
                } else {
                    print("메시지를 서브컬렉션에 성공적으로 추가했습니다.")

                    DispatchQueue.main.async {
                        self.messageTextField.text = ""
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chattingRoom.dataSource = self
        chattingRoom.delegate = self
        LoadMessages()
        messageTextField.placeholder = "채팅"
    }
    
     func LoadMessages() {
         if let userEmail = UserDefaults.standard.string(forKey: "UserEmailKey"), let chatUser = chatUser {
                 // 사용자 이메일과 채팅 사용자 이메일을 정렬
                 let sortedEmails = [userEmail, chatUser].sorted()
                 let chatDocumentID = sortedEmails[0] + "&" + sortedEmails[1]
                 
                 let chatDocumentReference = db.collection("채팅").document(chatDocumentID)
            
            // "메시지" 서브컬렉션의 문서를 날짜 순으로 정렬
            chatDocumentReference.collection("메시지")
                .order(by: "date")
                .addSnapshotListener { (querySnapshot, error) in
                    self.messages = []
                    
                    if let error = error {
                        print("메시지를 가져오는 데 실패했습니다: \(error.localizedDescription)")
                    } else {
                        if let snapshotDocuments = querySnapshot?.documents {
                            for doc in snapshotDocuments {
                                let data = doc.data()
                                if let sender = data["sender"] as? String, let body = data["body"] as? String {
                                    self.messages.append(Message(sender: sender, body: body))
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.chattingRoom.reloadData()
                                self.scrollToLastMessage()
                            }
                        }
                    }
                }
        }
    }

    func scrollToLastMessage() {
        if self.messages.isEmpty {
            return
        }
        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
        self.chattingRoom.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }



}

extension ChatRoomViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count // 메시지 배열의 크기를 반환
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        let messageCell = tableView.dequeueReusableCell(withIdentifier: "ChatRoomTableViewCell", for: indexPath) as! ChatRoomTableViewCell
        
        
        if message.sender == UserDefaults.standard.string(forKey: "UserEmailKey") {
            messageCell.leftImageView.isHidden = true
            messageCell.nickName.isHidden = true
            messageCell.messageLabel.textColor = UIColor.black
            messageCell.messageLabel.textAlignment = .right
        } else {
            messageCell.leftImageView.isHidden = false
            messageCell.nickName?.isHidden = false
            messageCell.messageLabel.textColor = UIColor.brown
            messageCell.messageLabel.textAlignment = .left
        }

        messageCell.messageLabel.lineBreakMode = .byWordWrapping
        messageCell.messageLabel.numberOfLines = 0

        messageCell.messageLabel.text = message.body
        messageCell.nickName.text = self.nickName
        messageCell.leftImageView.image = self.profileImage
        if messageCell.leftImageView?.image == nil {
            messageCell.leftImageView?.image = UIImage(named: "free-icon-user-7718888.png")
        }
        messageCell.leftImageView?.layer.cornerRadius = messageCell.leftImageView.frame.size.width / 2
        messageCell.leftImageView?.clipsToBounds = true
        messageCell.leftImageView?.contentMode = .scaleAspectFill
        
        print(message.body)
        return messageCell
    }
}

