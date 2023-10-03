//
//  RegisterInfoViewController.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/08/26.
//

import UIKit
import Firebase
import FirebaseFirestore
import UITextView_Placeholder
import PhotosUI
import NMapsMap


class RegisterInfoViewController: UIViewController {
    
    @IBOutlet var titleLabel: UITextField!
    @IBOutlet var mainTextLabel: UITextView!
    @IBOutlet var lostItemPhoto: UIImageView!
    @IBOutlet var lostItemPhoto2: UIImageView!
    @IBOutlet var lostItemPhoto3: UIImageView!
    
    let db = Firestore.firestore()
    var documentRef: DocumentReference?
    let storage = Storage.storage()
    var imagesToUpload: [UIImage?] = [] // 이미지를 저장할 배열
    var centerLatLng: NMGLatLng?
    var centerX: CGFloat?
    var centerY: CGFloat?
    var emptyLabel: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.placeholder = "제목을 입력하세요."
        mainTextLabel.placeholder = "글 내용을 입력하세요."
        addGestureRecognizer()
        //테두리 두께 설정
        mainTextLabel.layer.borderWidth = 1.0
        // 테두리 색상 설정
        mainTextLabel.layer.borderColor = UIColor.lightGray.cgColor
        LostItemImage()
        TabBarItem()
    }
    
    func LostItemImage () {
        lostItemPhoto.layer.borderWidth = 1.0 // 테두리 두께
        lostItemPhoto.layer.borderColor = UIColor.lightGray.cgColor // 테두리 색상
        lostItemPhoto.layer.cornerRadius = 3.0 // 테두리 모서리 반경 (원하는 값으로 조정)
        lostItemPhoto.clipsToBounds = true
        lostItemPhoto2.layer.borderWidth = 1.0
        lostItemPhoto2.layer.borderColor = UIColor.lightGray.cgColor
        lostItemPhoto2.layer.cornerRadius = 3.0
        lostItemPhoto2.clipsToBounds = true
        lostItemPhoto3.layer.borderWidth = 1.0
        lostItemPhoto3.layer.borderColor = UIColor.lightGray.cgColor
        lostItemPhoto3.layer.cornerRadius = 3.0
        lostItemPhoto3.clipsToBounds = true
    }
    
    func TabBarItem() {
        let appearance = UITabBarAppearance()
            
            // 타이틀의 일반 상태 (선택되지 않은 상태) 색상 설정
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.darkGray] // 원하는 색상으로 변경
            
            // 타이틀의 선택된 상태 색상 설정
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemBlue] // 원하는 색상으로 변경
        UITabBar.appearance().standardAppearance = appearance
    }
    
   
    @IBAction func completeBtn(_ sender: Any) {
        if titleLabel.text != nil && mainTextLabel.text != nil && lostItemPhoto.image != UIImage(systemName: "photo.artframe") {
            SetData()
            let storyboard = UIStoryboard(name: "Register", bundle: nil)
            guard let RegisterViewControllerVC = storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as? RegisterViewController else { return }
            RegisterViewControllerVC.mainTableView?.reloadData()
            //이미지파일 가지고 오기
            imagesToUpload = [lostItemPhoto.image, lostItemPhoto2.image, lostItemPhoto3.image]
            uploadImagesSequentially(index: 0)
        } else {
            // 알림 창 표시
               let alertController = UIAlertController(title: "게시글 작성 오류", message: "내용을 확인해주세요.", preferredStyle: .alert)
               
               // 확인 버튼 추가
               let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
               alertController.addAction(okAction)
               
               // 알림 창 표시
               present(alertController, animated: true, completion: nil)
        }
    }
    
    
    //정보를 db에 넘겨줌
    func SetData() {
        // Firestore 참조 생성
        let db = Firestore.firestore()
        
        // 컬렉션에 대한 참조 생성
        let collectionRef = db.collection("게시글")
        
        // 문서에 대한 참조 생성
        let documentRef = collectionRef.document(self.titleLabel?.text ?? "")
        
        
        // 컬렉션 존재 여부 확인
        collectionRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting collection documents: \(error)")
                return
            }
            
            if snapshot?.isEmpty == true {
                // 컬렉션이 비어있으면 컬렉션 생성 후 문서 업데이트 작업 수행
                let data: [String: Any] = ["내용": self.mainTextLabel.text ?? "", "유저": UserDefaults.standard.string(forKey: "UserEmailKey")!]
                documentRef.setData(data) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Collection created, document added and updated")
                    }
                }
            } else {
                // 컬렉션이 존재하면 문서 존재 여부 확인 후 업데이트 작업 수행
                documentRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        // 문서가 존재하면 업데이트 작업 수행
                        documentRef.updateData(["내용": self.mainTextLabel.text ?? "", "유저": UserDefaults.standard.string(forKey: "UserEmailKey")!]) { err in
                            if let err = err {
                                print("Error updating document: \(err)")
                            } else {
                                print("Document updated")
                            }
                        }
                    } else {
                        // 문서가 존재하지 않으면 문서 생성 후 업데이트 작업 수행
                        let data: [String: Any] = ["내용": self.mainTextLabel.text ?? "", "유저": UserDefaults.standard.string(forKey: "UserEmailKey")!]
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
        }
        let storyboard = UIStoryboard(name: "MapMarkerRegister", bundle: nil)
        guard let MapMarkerViewControllerVC = storyboard.instantiateViewController(withIdentifier: "MapMarkerViewController") as? MapMarkerViewController else { return }
        MapMarkerViewControllerVC.titleLabel = self.titleLabel.text!
        present(MapMarkerViewControllerVC, animated: true)
    }
    
    //이미지 파이어베이스로 업로드
    func uploadimage(img: UIImage, completion: @escaping (Bool) -> Void) {
        guard let data = img.jpegData(compressionQuality: 0.1) else {
            completion(false)
            return
        }
        
        let fileName = generateUniqueFileName() // 중복되지 않는 파일 이름 생성
        let metaData = StorageMetadata()
        metaData.contentType = "image/png"
        
        storage.reference().child(fileName).putData(data, metadata: metaData) { (metaData, error) in
            if let error = error {
                print(error.localizedDescription)
                completion(false)
            } else {
                print("Image uploaded successfully")
                self.downloadAndStoreURL(fileName: fileName)
                completion(true)
            }
        }
    }

    func downloadAndStoreURL(fileName: String) {
        let fileRef = storage.reference().child(fileName)
        fileRef.downloadURL { url, error in
            if let error = error {
                print(error.localizedDescription)
            } else if let downloadURL = url {
                self.documentRef = self.db.collection("게시글").document(self.titleLabel.text ?? "")
                self.documentRef?.updateData(["분실물 사진": FieldValue.arrayUnion([downloadURL.absoluteString])]) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Document added with profile image")

                    }
                }
            }
        }
    }

    func generateUniqueFileName() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomString = UUID().uuidString
        return "\(timestamp)_\(randomString).png"
    }

    func uploadImagesSequentially(index: Int) {
        guard index < imagesToUpload.count else {
            // 모든 이미지를 업로드한 경우
            print("All images uploaded")
            return
        }
        
        if let image = imagesToUpload[index] {
            uploadimage(img: image) { success in
                if success {
                    // 다음 이미지 업로드
                    self.uploadImagesSequentially(index: index + 1)
                    
                } else {
                    print("Image upload failed")
                }
            }
        } else {
            // 이미지가 nil인 경우
            uploadImagesSequentially(index: index + 1)
        }
    }

    
    func openAlbum() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared()) //환경설정에 관함
        configuration.selectionLimit = 3 //사진선택 갯수 제한
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated:  true)
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
    
    func addGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tappedUIImageView(_:)))
        self.lostItemPhoto.addGestureRecognizer(tapGestureRecognizer)
        self.lostItemPhoto.isUserInteractionEnabled = true
    }
    
    // objc 함수 구현
    @objc func tappedUIImageView(_ gesture: UITapGestureRecognizer) {
        self.checkpermission()
    }
    
    
    
   
}



extension RegisterInfoViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        // 사진을 순서대로 적용할 이미지 뷰들의 배열
        let imageViews: [UIImageView] = [lostItemPhoto, lostItemPhoto2, lostItemPhoto3]
        
        for (index, result) in results.prefix(imageViews.count).enumerated() {
            let imageView = imageViews[index]
            
            let selectedImageProvider = result.itemProvider
            
            if selectedImageProvider.canLoadObject(ofClass: UIImage.self) {
                selectedImageProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if let image = image as? UIImage {
                        // 이미지가 성공적으로 로드되었을 경우의 처리
                        DispatchQueue.main.async {
                            // 이미지 설정 및 화면 갱신 등을 진행
                            imageView.contentMode = .scaleAspectFill
                            imageView.image = image
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
