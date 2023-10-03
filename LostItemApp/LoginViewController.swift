//
//  LoginViewController.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/07/11.
//

import UIKit
import FirebaseCore
import FirebaseAnalytics
import FirebaseAuth
import GoogleSignIn
import KakaoSDKAuth
import AuthenticationServices

class LoginViewController: UIViewController, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
        
    }
    
    
    @IBOutlet var GoogleLoginBtn: GIDSignInButton!
    
    //구글로그인 기능
    @IBAction func GoogleBtnAction(_ sender: GIDSignInButton) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self as UIViewController) { user, error in
            
            guard error == nil else { return }
            
            guard let authentication = user?.authentication,
                  let idToken = authentication.idToken
            else {
                return
            }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: authentication.accessToken)
            Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                // 로그인 오류 처리
                print("Google 로그인 실패: \(error.localizedDescription)")
                return
            }
                
                // 로그인 성공 시 처리
                if let user = authResult?.user {
                    // 로그인한 사용자 정보 사용 가능
                    UserDefaults.standard.set("Google", forKey: "SocialLogin")
                    UserDefaults.standard.set(Auth.auth().currentUser?.email, forKey: "UserEmailKey")
                    print("Google 로그인 성공: \(user.uid)")
                }
                
            }
            let storyboard = UIStoryboard(name: "TabBar", bundle: nil)
            guard let TabBarControllerVC = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController else { return }
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(TabBarControllerVC, animated: false)
        }
    }
    
    
    
    let authorizationAppleIDButton = ASAuthorizationAppleIDButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProviderLoginView()
        
    }

    
    
    @IBOutlet weak var appleloginStack: UIStackView!
    //카카오 로그인 후 화면 전환
    lazy var kakaoAuthVM: KakaoAuthVM = { KakaoAuthVM() }()
    @IBAction func KakaoLoginBtn(_ sender: Any) {
        kakaoAuthVM.handleKakaoLogin{ [weak self] success in
            if success {
                UserDefaults.standard.set("Kakao", forKey: "SocialLogin")
                let storyboard = UIStoryboard(name: "TabBar", bundle: nil)
                guard let TabBarControllerVC = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController else { return }
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(TabBarControllerVC, animated: false)
            } else {
                print("카카오 로그인 실패.")
            }
        }
        
    }
    
    func setupProviderLoginView() {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
        self.appleloginStack.addArrangedSubview(button)
    }
    
    @objc func handleAuthorizationAppleIDButtonPress(_ sender: ASAuthorizationAppleIDButton){
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        
        let controller = ASAuthorizationController(authorizationRequests:  [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

//애플로그인 정보 처리 
extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
            
        case let appleIDcredential as ASAuthorizationAppleIDCredential:
            let userIdentifier = appleIDcredential.user
            let fullName = appleIDcredential.fullName
            let email = appleIDcredential.email
            
            
            //파이어베이스로 사용자 연결
            Auth.auth().signIn(withEmail: email ?? "", password: "randompassword") { (authResult, error) in
                        if let error = error {
                            print("Error creating user: \(error.localizedDescription)")
                            return
                        }
                        
                        if let user = authResult?.user {
                            print("User created with email: \(user.email ?? "")")
                        
                    }
                }
        
            print("#1", userIdentifier)
            print("#2", fullName as Any)
            print("#3", email as Any)
            
            //UserDefaults에 정보추가
            UserDefaults.standard.set(appleIDcredential.email, forKey: "UserEmailKey")
            UserDefaults.standard.set("Apple", forKey: "SocialLogin")

        case let passwordCredential as ASPasswordCredential:
            let userName = passwordCredential.user
            let password = passwordCredential.password
            
            print("#4", userName)
            print("#5", password)
            
        default:
            break
        }
        let storyboard = UIStoryboard(name: "TabBar", bundle: nil)
        guard let TabBarControllerVC = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController else { return }
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(TabBarControllerVC, animated: false)
    }
    
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("#6", error)
    }
}
    
