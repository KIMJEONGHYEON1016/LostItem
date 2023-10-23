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
    @IBAction func GoogleBtnAction(sender: Any) {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            guard error == nil else { return }
            guard let signInResult = signInResult else { return }

                let user = signInResult.user

                let emailAddress = user.profile?.email
            Auth.auth().signIn(withEmail: emailAddress ?? "", password: "randompassword") { (authResult, error) in
                        if let error = error {
                            print("Error creating user: \(error.localizedDescription)")
                            return
                        }
                        
                        if let user = authResult?.user {
                            print("User created with email: \(emailAddress ?? "")")
                        
                    }
                }
            
            UserDefaults.standard.set("Google", forKey: "SocialLogin")
            UserDefaults.standard.set(emailAddress, forKey: "UserEmailKey")
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
    
