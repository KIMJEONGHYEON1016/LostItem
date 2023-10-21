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
    @IBOutlet var chattingUser: UILabel!
    @IBOutlet var messageTextField: UITextView!
    @IBOutlet var sendMessage: UIButton!
    
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
        self.dismiss(animated: true)
        let storyboard = UIStoryboard(name: "TabBar", bundle: nil)
        guard let TabBarControllerVC = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController else { return }
        TabBarControllerVC.selectedIndex = 2

        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(TabBarControllerVC, animated: false)
    }
    
    @IBAction func DeleteBtn(_ sender: Any) {
            //알림창 생성
            let alertController = UIAlertController(title: "채팅방 나가기", message: "정말로 채팅방을 나가겠습니까?", preferredStyle: .alert)
            
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
    
    //삭제 함수
    func DeleteDocument() {
        let db = Firestore.firestore()
        if let messageSender = UserDefaults.standard.string(forKey: "UserEmailKey"),
           let chatUser = chatUser {
            let sortedEmails = [messageSender, chatUser].sorted()
            
            let chatDocumentID = sortedEmails[0] + "&" + sortedEmails[1]
            let docRef = db.collection("채팅").document(chatDocumentID)
            
            // 문서 삭제
            docRef.delete { (error) in
                if let error = error {
                    print("문서 삭제 중 오류 발생: \(error)")
                } else {
                    print("문서 삭제 성공")
                }
            }
        }
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        if messageTextField.text == "" {
                //메세지가 공백일경우 무반응
        } else {
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
            sendMessage.setImage(UIImage(named: "chat-btn2"), for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chattingRoom.dataSource = self
        chattingRoom.delegate = self
        LoadMessages()
        messageTextField.placeholder = "채팅"
        messageTextField.layer.cornerRadius = 3.0
        let customColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        chattingRoom?.layer.borderWidth = 1.0
        chattingRoom?.layer.borderColor = customColor.cgColor
        chattingRoom?.layer.cornerRadius = 3.0
        NotificationCenter.default.addObserver(self, selector: #selector(textViewTextChanged), name: UITextView.textDidChangeNotification, object: messageTextField)
        
    }
    
    
    @objc func textViewTextChanged() {
        if let text = messageTextField.text, !text.isEmpty {
            // 텍스트 뷰가 비어 있지 않으면 버튼의 이미지를 설정
            sendMessage.setImage(UIImage(named: "chat-btn"), for: .normal)
        } else {
            sendMessage.setImage(UIImage(named: "chat-btn2"), for: .normal)
        }
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
        
        messageCell.messageBubble.addSubview(messageCell.messageLabel)
        messageCell.MymessageBubble.addSubview(messageCell.myMessage)

        if message.sender == UserDefaults.standard.string(forKey: "UserEmailKey") {
            messageCell.myMessage.text = message.body
            messageCell.leftImageView.isHidden = true
            messageCell.myMessage.textAlignment = .right
            messageCell.myMessage.lineBreakMode = .byWordWrapping
            messageCell.myMessage.numberOfLines = 0
            messageCell.myMessage.isHidden = false
            messageCell.messageLabel.isHidden = true
            messageCell.messageBubble.isHidden = true
            messageCell.MymessageBubble.isHidden = false
            messageCell.MymessageBubble.layer.cornerRadius = 5.0

        } else {
            messageCell.messageLabel.text = message.body
            messageCell.leftImageView.isHidden = false
            messageCell.messageLabel.textColor = UIColor.black
            messageCell.messageLabel.textAlignment = .left
            messageCell.messageLabel.lineBreakMode = .byWordWrapping
            messageCell.messageLabel.numberOfLines = 0
            messageCell.myMessage.isHidden = true
            messageCell.messageLabel.isHidden = false
            messageCell.messageBubble.isHidden = false
            messageCell.messageBubble.layer.cornerRadius = 5.0
            messageCell.messageBubble.isHidden = false
            messageCell.MymessageBubble.isHidden = true

        }

        
        self.chattingUser.text = self.nickName
        messageCell.leftImageView.image = self.profileImage
        if messageCell.leftImageView?.image == nil {
            messageCell.leftImageView?.image = UIImage(named: "user.png")
        }
        messageCell.leftImageView?.layer.cornerRadius = messageCell.leftImageView.frame.size.width / 2
        messageCell.leftImageView?.clipsToBounds = true
        messageCell.leftImageView?.contentMode = .scaleAspectFill
        
        print(message.body)
        return messageCell
    }
}

