//
//  SceneDelegate.swift
//  dprakhovPW4
//
//  Created by Данил Прахов on 11.11.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Убеждаемся, что сцена, к которой мы подключаемся, является UIWindowScene.
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 1. Создаем для неё окно размером с экран.
        let window = UIWindow(windowScene: windowScene)
        
        // 2. Создаем наш главный (корневой) экран.
        let rootVC = WishMakerViewController()
        
        // 3. Оборачиваем его в UINavigationController для управления стеком экранов.
        let navigationController = UINavigationController(rootViewController: rootVC)
        
        // 4. Устанавливаем UINavigationController как главный контроллер окна.
        window.rootViewController = navigationController
        
        // 5. Сохраняем ссылку на это окно и делаем его видимым.
        self.window = window
        window.makeKeyAndVisible()
    }
}
