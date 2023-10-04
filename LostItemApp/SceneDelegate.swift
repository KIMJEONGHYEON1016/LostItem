//
//  SceneDelegate.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/07/11.
//

import UIKit
import KakaoSDKAuth


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var isLogged: Bool = false
    var window: UIWindow?

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
            if let url = URLContexts.first?.url {
                if (AuthApi.isKakaoTalkLoginUrl(url)) {
                    _ = AuthController.handleOpenUrl(url: url)
                }
            }
        }
    //화면전환 함수
    func changeRootViewController (_ vc: UIViewController, animated: Bool) {
        guard let window = self.window else { return }
        window.rootViewController = vc
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
      
        guard let _ = (scene as? UIWindowScene) else { return }
        
        let storyboard = UIStoryboard(name: "TabBar", bundle: nil)
        
        let storyboard2 = UIStoryboard(name: "Main", bundle: nil)
        
        if UserDefaults.standard.string(forKey: "UserEmailKey") != nil {
            // UserEmailKey 값이 존재하는 경우
            isLogged = true
        } else {
            // UserEmailKey 값이 존재하지 않는 경우
            isLogged = false
        }
   
        
        if isLogged == false {
            guard let loginVC = storyboard2.instantiateViewController(withIdentifier: "LoginView") as? LoginViewController else { return }
            window?.rootViewController = loginVC
        } else {
            guard let TabBarControllerVC = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController else { return }
            window?.rootViewController = TabBarControllerVC
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

