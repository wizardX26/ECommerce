import Foundation

final class AppDIContainer {
    
    // Shared singleton instance
    static let shared: AppDIContainer = {
        print("🛒 [AppDIContainer] Creating shared singleton instance")
        return AppDIContainer()
    }()
    
    lazy var appConfiguration = AppConfiguration()
    
    // MARK: - Network
    lazy var apiDataTransferService: DataTransferService = {
        // Keep api_key in query parameters for existing working cases
        // Bearer token will be added to Authorization header when available (for authenticated endpoints)
        let baseURLString = appConfiguration.apiBaseURL
        guard let baseURL = URL(string: baseURLString) else {
            fatalError("Invalid API Base URL: \(baseURLString)")
        }
        print("🔧 [DIContainer] Creating API DataTransferService with baseURL: \(baseURL.absoluteString)")
        
        let config = ApiDataNetworkConfig(
            baseURL: baseURL,
            queryParameters: [
                "api_key": appConfiguration.apiKey,
                "language": NSLocale.preferredLanguages.first ?? "en"
            ]
        )
        
        let apiDataNetwork = DefaultNetworkService(config: config)
        return DefaultDataTransferService(with: apiDataNetwork)
    }()

    lazy var productsDataTransferService: DataTransferService = {
        let baseURLString = appConfiguration.apiBaseURL
        guard let baseURL = URL(string: baseURLString) else {
            fatalError("Invalid API Base URL: \(baseURLString)")
        }
        print("🔧 [DIContainer] Creating Products DataTransferService with baseURL: \(baseURL.absoluteString)")
        
        let config = ApiDataNetworkConfig(
            baseURL: baseURL,
            headers: [
                "X_API_KEY": appConfiguration.apiKey
            ]
        )
        let productsDataNetwork = DefaultNetworkService(config: config)
        return DefaultDataTransferService(with: productsDataNetwork)
    }()
    
    // MARK: - DIContainers of scenes
    
    func makeProductsSceneDIContainer() -> ProductsSceneDIContainer {
        let dependencies = ProductsSceneDIContainer.Dependencies(
            productsDataTransferService: productsDataTransferService
        )
        return ProductsSceneDIContainer(dependencies: dependencies)
    }
    
    func makeCategorySceneDIContainer() -> CategorySceneDIContainer {
        let dependencies = CategorySceneDIContainer.Dependencies(
            productsDataTransferService: productsDataTransferService
        )
        return CategorySceneDIContainer(dependencies: dependencies)
    }
    
    func makeSearchSceneDIContainer() -> SearchSceneDIContainer {
        let dependencies = SearchSceneDIContainer.Dependencies(
            apiDataTransferService: productsDataTransferService
        )
        return SearchSceneDIContainer(dependencies: dependencies)
    }
    
    func makeAuthSceneDIContainer() -> AuthSceneDIContainer {
        let dependencies = AuthSceneDIContainer.Dependencies(
            apiDataTransferService: apiDataTransferService,
            appDIContainer: self
        )
        return AuthSceneDIContainer(dependencies: dependencies)
    }
    
    func makeAddressDIContainer() -> AddressDIContainer {
        let dependencies = AddressDIContainer.Dependencies(
            apiDataTransferService: apiDataTransferService
        )
        return AddressDIContainer(dependencies: dependencies)
    }
    
    func makeLocationListDIContainer() -> LocationListDIContainer {
        let dependencies = LocationListDIContainer.Dependencies(
            apiDataTransferService: apiDataTransferService
        )
        return LocationListDIContainer(dependencies: dependencies)
    }
    
    func makeProfileDIContainer() -> ProfileDIContainer {
        let dependencies = ProfileDIContainer.Dependencies(
            apiDataTransferService: apiDataTransferService
        )
        return ProfileDIContainer(dependencies: dependencies)
    }
    
    func makePaymentCardDIContainer() -> PaymentCardDIContainer {
        let dependencies = PaymentCardDIContainer.Dependencies(
            paymentCardDataTransferService: apiDataTransferService
        )
        return PaymentCardDIContainer(dependencies: dependencies)
    }
    
    func makeOrderDIContainer() -> OrderDIContainer {
        let dependencies = OrderDIContainer.Dependencies(
            orderDataTransferService: apiDataTransferService,
            paymentCardDataTransferService: apiDataTransferService
        )
        return OrderDIContainer(dependencies: dependencies)
    }
    
    func makeCheckoutSceneDIContainer() -> CheckoutSceneDIContainer {
        let dependencies = CheckoutSceneDIContainer.Dependencies(
            orderDataTransferService: apiDataTransferService,
            paymentCardDataTransferService: apiDataTransferService,
            addressDIContainer: makeAddressDIContainer()
        )
        return CheckoutSceneDIContainer(dependencies: dependencies)
    }
    
    func makeProductDetailDIContainer() -> ProductDetailDIContainer {
        return ProductDetailDIContainer()
    }
    
    // Shared instance to ensure same SideMenuController is used everywhere
    private lazy var sharedSideMenuSceneDIContainer: SideMenuSceneDIContainer = {
        let dependencies = SideMenuSceneDIContainer.Dependencies(
            addressDIContainer: makeAddressDIContainer(),
            paymentCardDIContainer: makePaymentCardDIContainer()
        )
        return SideMenuSceneDIContainer(dependencies: dependencies)
    }()
    
    func makeSideMenuSceneDIContainer() -> SideMenuSceneDIContainer {
        return sharedSideMenuSceneDIContainer
    }
    
    // Shared instance to ensure same CartController is used everywhere
    private lazy var sharedCartSceneDIContainer: CartSceneDIContainer = {
        print("🛒 [AppDIContainer] Creating shared CartSceneDIContainer (lazy initialization)")
        let container = CartSceneDIContainer()
        print("   Container instance ID: \(ObjectIdentifier(container))")
        return container
    }()
    
    func makeMainSceneDIContainer() -> MainSceneDIContainer {
        let dependencies = MainSceneDIContainer.Dependencies(
            sideMenuSceneDIContainer: makeSideMenuSceneDIContainer(),
            appDIContainer: self
        )
        return MainSceneDIContainer(dependencies: dependencies)
    }
    
    func makeOnboardSceneDIContainer() -> OnboardSceneDIContainer {
        let dependencies = OnboardSceneDIContainer.Dependencies(
            authSceneDIContainer: makeAuthSceneDIContainer(),
            mainSceneDIContainer: makeMainSceneDIContainer()
        )
        return OnboardSceneDIContainer(dependencies: dependencies)
    }
    
    func makeCartSceneDIContainer() -> CartSceneDIContainer {
        print("🛒 [AppDIContainer] makeCartSceneDIContainer called")
        print("   Returning sharedCartSceneDIContainer instance ID: \(ObjectIdentifier(sharedCartSceneDIContainer))")
        return sharedCartSceneDIContainer
    }
    
    func makeOrderContainerDIContainer() -> OrderContainerDIContainer {
        let dependencies = OrderContainerDIContainer.Dependencies(
            orderDataTransferService: apiDataTransferService
        )
        return OrderContainerDIContainer(dependencies: dependencies)
    }
    
    func makeOrderDetailDIContainer() -> OrderDetailDIContainer {
        let dependencies = OrderDetailDIContainer.Dependencies(
            orderDetailUseCase: makeOrderDetailUseCase()
        )
        return OrderDetailDIContainer(dependencies: dependencies)
    }
    
    func makeNotificationSceneDIContainer() -> NotificationSceneDIContainer {
        let dependencies = NotificationSceneDIContainer.Dependencies(
            notificationDataTransferService: apiDataTransferService
        )
        return NotificationSceneDIContainer(dependencies: dependencies)
    }
    
    // MARK: - Use Cases
    
    private func makeOrderDetailUseCase() -> OrderDetailUseCase {
        let repository = makeOrderDetailRepository()
        return DefaultOrderDetailUseCase(orderDetailRepository: repository)
    }
    
    // MARK: - Repositories
    
    private func makeOrderDetailRepository() -> OrderDetailRepository {
        return DefaultOrderDetailRepository(
            dataTransferService: apiDataTransferService
        )
    }
}
