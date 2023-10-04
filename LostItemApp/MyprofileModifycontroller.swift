//
//  MyprofileModifycontroller.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/08/08.
//


import UIKit
import PhotosUI
import FirebaseFirestore
import FirebaseStorage

class MyprofileModifycontroller: UIViewController {
    
    @IBOutlet var NickName: UITextField!
    @IBOutlet var profileImage: UIImageView!
    var nickName: String?
    var profileimage: UIImage?
    
    let db = Firestore.firestore()
    var ref: DocumentReference?
    let storage = Storage.storage()
    
    let alertController = UIAlertController(title: "올릴 방식을 선택하세요", message: "사진 찍기 또는 앨범에서 선택", preferredStyle: .actionSheet)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NickName.delegate = self
        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
        profileImage.clipsToBounds = true
        enrollAlertEvent()
        addGestureRecognizer()
        
        NickName.text = nickName
        profileImage.image = profileimage
        
        if profileImage.image == nil {
            profileImage.image = UIImage(named: "free-icon-user-7718888.png")
        }
        profileImage.contentMode = .scaleAspectFill
        if NickName.text == nil{
            NickName.text = "닉네임"
        }
    }
    
    // 다른 곳 클릭하면 확정 짓기?
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func BackBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    // 화면 이동 및 마이페이지 정보 변경
    @IBAction func CompleteBtn(_ sender: Any) {
        
        if let newNickname = NickName.text, !newNickname.isEmpty {
                let db = Firestore.firestore()
                let usersCollection = db.collection("Users")
                
                // 모든 문서에서 "닉네임" 필드를 가진 데이터를 검색
            usersCollection.whereField("닉네임", isEqualTo: newNickname).whereField(FieldPath.documentID(), isNotEqualTo: UserDefaults.standard.string(forKey: "UserEmailKey")!).getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error querying Firestore: \(error)")
                        return
                    }
                    
                    if let documents = querySnapshot?.documents, !documents.isEmpty {
                        // "닉네임" 필드를 가진 문서가 이미 존재함
                        self.showAlert(title: "닉네임 중복", message: "입력한 닉네임은 이미 사용 중입니다.")
                    } else {
                        // "닉네임" 필드를 가진 문서가 없음, 닉네임 업데이트 및 작업 수행
                        let storyboard = UIStoryboard(name: "MyPage", bundle: nil)
                        guard let myPageVC = storyboard.instantiateViewController(withIdentifier: "MyPagecontroller") as? MyPagecontroller else { return }
                        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(myPageVC, animated: true)
                        myPageVC.NickName?.text = newNickname
                        myPageVC.NickName?.sizeToFit()
                        myPageVC.profileimage?.image = self.profileImage?.image
                        self.SetData()
                        // 이미지 파일 가져오기 및 업로드 로직 추가
                        let image = self.profileImage.image
                        self.uploadimage(img: image!)
                    }
                }
            } else {
                // 닉네임이 비어있는 경우
                showAlert(title: "변경 불가", message: "닉네임을 입력해주세요.")
            }
        }
    
        
        func showAlert(title: String, message: String) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
        
    //이미지 storage 업로드
    func uploadimage(img :UIImage){
            var data = Data()
            data = img.jpegData(compressionQuality: 0.1)!
            let filePath = UserDefaults.standard.string(forKey: "UserEmailKey")!
            let metaData = StorageMetadata()
            metaData.contentType = "image/png"
            storage.reference().child(filePath).putData(data,metadata: metaData){
                (metaData,error) in if let error = error{
                    print(error.localizedDescription)
                    return
                }else{
                    print("성공")
                    self.DownloadURL()
                        }
                    }
                }
    
    //프로필 사진을 Storage -> store로 이동
    func DownloadURL() {
        // Create a reference to the file you want to download
        let filePath = UserDefaults.standard.string(forKey: "UserEmailKey")!
        let starsRef = storage.reference().child(filePath)

        // Fetch the download URL
        starsRef.downloadURL { url, error in
            if let error = error {
                    print(error)
            } else {
                self.ref = self.db.collection("Users").document(UserDefaults.standard.string(forKey: "UserEmailKey")!)
                self.ref?.updateData(["프로필 사진":url?.absoluteString ?? ""]) { err in
                      if let err = err {
                          print("Error adding document: \(err)")
                      } else {
                          print("Document added with profile image")
                      }
                }
            }
        }
}
            
    
    
    //닉네임 Firestore 등록
    func SetData() {
        // Firestore 참조 생성
        let db = Firestore.firestore()

        // 문서에 대한 참조 생성
        let userEmail = UserDefaults.standard.string(forKey: "UserEmailKey") ?? ""
        let documentRef = db.collection("Users").document(userEmail)

        // 문서 존재 여부 확인
        documentRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // 문서가 존재하면 업데이트 작업 수행
                documentRef.updateData(["닉네임": self.NickName.text ?? ""]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Document updated")
                    }
                }
            } else {
                // 문서가 존재하지 않으면 문서 생성 후 업데이트 작업 수행
                let data: [String: Any] = ["닉네임": self.NickName.text ?? ""]
                documentRef.setData(data) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Document added and updated")
                    }
                }
            }
        }
    }


    
    // 앨범과 사진 촬영 이벤트 관리
    func enrollAlertEvent() {
        let photoLibraryAlertAction = UIAlertAction(title: "사진 앨범", style: .default) { (action) in
            self.checkpermission()
        }
        let cameraAlertAction = UIAlertAction(title: "카메라", style: .default) { (action) in
            self.openCamera()
        }
        let cancelAlertAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        self.alertController.addAction(photoLibraryAlertAction)
        self.alertController.addAction(cameraAlertAction)
        self.alertController.addAction(cancelAlertAction)
        guard let alertControllerPopoverPresentationController = alertController.popoverPresentationController else { return }
        prepareForPopoverPresentation(alertControllerPopoverPresentationController)
    }
    
    // 앨범 오픈
    func openAlbum() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared()) //환경설정에 관함
        configuration.selectionLimit = 1 //사진선택 갯수 제한
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated:  true)
    }
        
    func openCamera() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1 //사진선택 갯수 제한
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func checkpermission(){    //권합접근허용
            if PHPhotoLibrary.authorizationStatus() == .authorized || PHPhotoLibrary.authorizationStatus() == .limited{
                DispatchQueue.main.async {
                    self.openAlbum()
                }
            }else if PHPhotoLibrary.authorizationStatus() == .denied{
                DispatchQueue.main.async {
                    self.showAuthorizationdeinedAlert()
                }
            }else if PHPhotoLibrary.authorizationStatus() == .notDetermined{
                PHPhotoLibrary.requestAuthorization { status in
                    self.checkpermission()
                }
            }
        }
    func showAuthorizationdeinedAlert() {
                let alert = UIAlertController(title: "포토라이브러리 접근 권한을 활성화 해주세요", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "닫기", style: .cancel,handler: nil))
                alert.addAction(UIAlertAction(title: "설정으로 가기", style: .default, handler: {
                    action in
                    
                    guard let url = URL(string: UIApplication.openSettingsURLString) else{
                        return
                    }
                    if UIApplication.shared.canOpenURL(url) { //url로 이동하는 기능 can으로 가능한지 확인
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } //내 설정으로 가기
                   
            }))
                self.present(alert, animated: true)
        }
    
    // 이미지 클릭시 제스처 기능 구현
    func addGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tappedUIImageView(_:)))
        self.profileImage.addGestureRecognizer(tapGestureRecognizer)
        self.profileImage.isUserInteractionEnabled = true
    }
    
    // objc 함수 구현
    @objc func tappedUIImageView(_ gesture: UITapGestureRecognizer) {
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
}

//alertcontroller로 선택
extension MyprofileModifycontroller: UIPopoverPresentationControllerDelegate {
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        if let popoverPresentationController = self.alertController.popoverPresentationController {
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverPresentationController.permittedArrowDirections = []
        }
    }
}

extension MyprofileModifycontroller: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let selectedImageProvider = results.first?.itemProvider {
            if selectedImageProvider.canLoadObject(ofClass: UIImage.self) {
                selectedImageProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if let image = image as? UIImage {
                        // 이미지가 성공적으로 로드되었을 경우의 처리
                        DispatchQueue.main.async {
                            // 이미지 설정 및 화면 갱신 등을 진행
                            self.profileImage.image = image
                            
                        }
                    } else if let error = error {
                        // 에러 처리
                        print("Error loading image: \(error)")
                    }
                }
            } else {
                // UIImage를 로드할 수 없는 경우 처리
                print("Selected item provider cannot load UIImage.")
                
            }
        }
    }
}

extension MyprofileModifycontroller: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
           let currentText = NickName.text ?? ""
           let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
           
           // 최대 글자 수 설정
           let maxLength = 6
           
           return newText.count <= maxLength
       }
}
