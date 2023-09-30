//
//  MyPagecontroller.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/07/21.
//

import Foundation
import FirebaseFirestore


class MyPagecontroller: UIViewController, UITextFieldDelegate {
    
    let db = Firestore.firestore()
    var ref: DocumentReference?
    
    @IBOutlet var NickName: UILabel!
    @IBOutlet var Residence: UITextField!
    @IBOutlet var profileimage: UIImageView!
    @IBOutlet var gratuity: UITextField!
    var nickName: String?
    var profileImage: UIImage?
    
    //정보 변경창으로 이동
    @IBAction func InformationModify(_ sender: Any) {
        let storyboard = UIStoryboard(name: "MyprofileModify", bundle: nil)
        let profileModifyVC = storyboard.instantiateViewController(withIdentifier: "MyprofileModifycontroller") as! MyprofileModifycontroller
        profileModifyVC.modalPresentationStyle = .fullScreen
        profileModifyVC.nickName = nickName
        profileModifyVC.profileimage = profileImage
        self.present(profileModifyVC, animated: true, completion: nil)
    }
    
    //뒤로가기 버튼
    @IBAction func BackBtn(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let MainVC = storyboard.instantiateViewController(withIdentifier: "MainView") as? ViewController else { return }
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(MainVC, animated: true)
    }
    @IBAction func MyPostBtn(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Register", bundle: nil)
        let RegisterViewControllerVC = storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
        RegisterViewControllerVC.modalPresentationStyle = .fullScreen
        self.present(RegisterViewControllerVC, animated: true, completion: nil)

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        profileimage.layer.cornerRadius = profileimage.frame.size.width / 2
        profileimage.clipsToBounds = true
        profileimage.contentMode = .scaleAspectFill
        UserDataLoad()
        if NickName.text == "" {
            NickName.text = "닉네임"
        }
        TabBarItem()
    }
    
    func TabBarItem() {
        let yourImage = UIImage(named: "free-icon-profile-7310896.png")
        tabBarItem.image = yourImage?.withRenderingMode(.alwaysOriginal)
        tabBarItem.selectedImage = yourImage
        let appearance = UITabBarAppearance()
            
            // 타이틀의 일반 상태 (선택되지 않은 상태) 색상 설정
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.darkGray] // 원하는 색상으로 변경
            
            // 타이틀의 선택된 상태 색상 설정
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemBlue] // 원하는 색상으로 변경
        UITabBar.appearance().standardAppearance = appearance
    }
    
    func UserDataLoad(){
        let docRef = db.collection("Users").document(UserDefaults.standard.string(forKey: "UserEmailKey")!)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                var nicknamedata = document.data()?["닉네임"] as? String
                if nicknamedata == nil {
                    nicknamedata = "닉네임"
                } else{
                    print("Document data: \(nicknamedata ?? "ab")")
                    self.NickName.text = nicknamedata
                    self.nickName = nicknamedata
                }
                // 이미지 URL 가져오기
                if let profileImageURLString = document.data()?["프로필 사진"] as? String,
                   let profileImageURL = URL(string: profileImageURLString) {
                    print("Document data: \(profileImageURL)")
                    
                    // 이미지 다운로드 및 표시
                    URLSession.shared.dataTask(with: profileImageURL) { (data, response, error) in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.profileimage.image = image
                                self.profileImage = image
                            }
                        }
                    }.resume()
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}
   
