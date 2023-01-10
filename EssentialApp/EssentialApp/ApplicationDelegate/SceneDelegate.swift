import os
import UIKit
import CoreData
import Combine
import EssentialFeed

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    private(set) lazy var delegates: [UIWindowSceneDelegate] = [
        ApplicationRouter(window: nil)
    ]
    
//    var window: UIWindow?
//    
    convenience init(httpClient: HTTPClient, store: FeedStore & FeedImageDataStore, scheduler: AnyDispatchQueueScheduler) {
        self.init()
        
        delegates = [ApplicationRouter(
            window: nil, httpClient: httpClient,
            store: store, scheduler: scheduler
        )]
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        delegates.forEach {
            $0.scene?(scene, willConnectTo: session, options: connectionOptions)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) { /*Non implemented*/ }

    func sceneDidBecomeActive(_ scene: UIScene) { /*Non implemented*/ }

    func sceneWillEnterForeground(_ scene: UIScene) { /*Non implemented*/ }

    func sceneDidEnterBackground(_ scene: UIScene) { /*Non implemented*/ }
    
    func sceneWillResignActive(_ scene: UIScene) {
        delegates.forEach { $0.sceneWillResignActive?(scene) }
    }
}
