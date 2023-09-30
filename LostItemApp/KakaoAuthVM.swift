//
//  KakaoAuthVM.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/07/12.
//

import Foundation
import Combine
import KakaoSDKAuth
import KakaoSDKUser
import FirebaseAuth

class KakaoAuthVM: ObservableObject {
    var subscription = Set<AnyCancellable>()
    typealias KakaoLoginCompletion = (Bool) -> Void
    
    var useremail = ""
    @Published var oauthToken: OAuthToken? // 토큰을 저장하는 프로퍼티
    
    func handleKakaoLogin(completion: @escaping KakaoLoginCompletion) {
        print("KakaoAuthVM - handleKakaoLogin() called")
        
        if (UserApi.isKakaoTalkLoginAvailable()) {
            UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
                if let error = error {
                    print(error)
                    completion(false)
                } else {
                    print("loginWithKakaoAccount() success.")
                    
                    // 요청할 동의 항목 설정
                    let scopes: [String] = ["account_email"] // 이메일 접근 권한
                    
                    // 사용자 동의 창 열기
                    UserApi.shared.loginWithKakaoAccount(scopes: scopes) { [weak self] (oauthToken, error) in
                        if let error = error {
                            print(error)
                            completion(false)
                        } else {
                            print("loginWithKakaoAccount(scopes:) success.")
                            self?.oauthToken = oauthToken // 토큰 저장
                            self?.ReadingAccount()
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    
    
    func ReadingAccount(){ UserApi.shared.me() {(user, error) in
        if let error = error {
            print(error)
        }
        else {
            self.useremail = user?.kakaoAccount?.email ?? ""
            //UserDefaults에 정보추가

            UserDefaults.standard.set(self.useremail, forKey: "UserEmailKey")
            UserDefaults.standard.set(self.oauthToken?.accessToken, forKey: "AccessTokenKey")
            UserDefaults.standard.set(self.oauthToken?.refreshToken, forKey: "RefreshTokenKey")
            
            _ = user
            self.addUserToFirebase(completion: { success in
                            // `success` 파라미터 값에 따라 처리
                            if success {
                                    } else {
                            }
                        })
                    }
                }
            
            
        
    }
    ////파이어베이스로 사용자 연결
    func addUserToFirebase(completion: @escaping KakaoLoginCompletion) {
            Auth.auth().createUser(withEmail: self.useremail, password: "randompassword") { authResult, error in
                if let error = error {
                    print("Error creating user: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let user = authResult?.user {
                    print("User created with email: \(user.email ?? "")")
                    completion(true)
                }
            }
        }
}
