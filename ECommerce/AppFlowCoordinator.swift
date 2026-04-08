import UIKit

final class AppFlowCoordinator {

    var navigationController: UINavigationController
    private let appDIContainer: AppDIContainer
    private var mainCoordinatingController: MainCoordinatingController?
    
    init(
        navigationController: UINavigationController,
        appDIContainer: AppDIContainer
    ) {
        self.navigationController = navigationController
        self.appDIContainer = appDIContainer
    }

    func start() {
        // Create MainSceneDIContainer and MainCoordinatingController
        let mainSceneDIContainer = appDIContainer.makeMainSceneDIContainer()
        let mainCoordinatingController = mainSceneDIContainer.makeMainCoordinatingController(
            navigationController: navigationController
        )
        self.mainCoordinatingController = mainCoordinatingController
        
        // Start MainCoordinatingController - this will set MainViewController as root
        mainCoordinatingController.start()
    }
}
