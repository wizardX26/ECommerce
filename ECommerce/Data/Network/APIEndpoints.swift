import Foundation

/// Main entry point for all API endpoints
/// Organizes endpoints by scene to keep code maintainable and scalable
/// 
/// **Note**: DTOs structs are mapped into Domains in repositories, 
/// and Repository protocols does not contain DTOs
struct APIEndpoints {
    
    // MARK: - Auth Endpoints
    
    /// Sign up endpoint
    static func signUp(with requestDTO: SignUpRequestDTO) -> Endpoint<SignUpResponseDTO> {
        return AuthEndpoints.signUp(with: requestDTO)
    }
    
    /// Login endpoint
    static func login(with requestDTO: LoginRequestDTO) -> Endpoint<LoginResponseDTO> {
        return AuthEndpoints.login(with: requestDTO)
    }
    
    /// Refresh token endpoint
    static func refreshToken(with requestDTO: RefreshTokenRequestDTO) -> Endpoint<RefreshTokenResponseDTO> {
        return AuthEndpoints.refreshToken(with: requestDTO)
    }
    
    /// Get user info endpoint
    static func getUserInfo() -> Endpoint<UserInfoResponseDTO> {
        return AuthEndpoints.getUserInfo()
    }
    
    /// Resend email verification endpoint
    static func resendEmailVerification() -> Endpoint<Void> {
        return AuthEndpoints.resendEmailVerification()
    }
    
    // MARK: - Products Endpoints
    
    /// Get products endpoint
    static func getProducts(with requestDTO: ProductsRequestDTO) -> Endpoint<ProductsResponseDTO> {
        return ProductsEndpoints.getProducts(with: requestDTO)
    }
    
    /// Search products endpoint
    static func searchProducts(query: String) -> Endpoint<ProductsResponseDTO> {
        return ProductsEndpoints.searchProducts(query: query)
    }
    
    // MARK: - Categories Endpoints
    
    /// Get categories endpoint
    static func getCategories() -> Endpoint<CategoriesResponseDTO> {
        return CategoriesEndpoints.getCategories()
    }
    
    // MARK: - Grocery Endpoints
    // Add grocery endpoints here when needed
    // Example:
    // static func getGroceryItems() -> Endpoint<GroceryResponseDTO> {
    //     return GroceryEndpoints.getGroceryItems()
    // }
    
    // MARK: - Address Endpoints
    
    /// Create address endpoint
    static func createAddress(with requestDTO: AddressRequestDTO) -> Endpoint<AddressResponseDTO> {
        return AddressEndpoints.createAddress(with: requestDTO)
    }
    
    /// Get addresses endpoint
    static func getAddresses() -> Endpoint<LocationListResponseDTO> {
        return LocationListEndpoints.getAddresses()
    }
    
    // MARK: - Profile Endpoints
    
    /// Update profile endpoint
    static func updateProfile(with requestDTO: UpdateProfileRequestDTO) -> Endpoint<UpdateProfileResponseDTO> {
        return ProfileEndpoints.updateProfile(with: requestDTO)
    }
    
    /// Change password endpoint
    static func changePassword(with requestDTO: ChangePasswordRequestDTO) -> Endpoint<ChangePasswordResponseDTO> {
        return ProfileEndpoints.changePassword(with: requestDTO)
    }
    
    // MARK: - Payment Card Endpoints
    
    /// Create customer endpoint
    static func createCustomer() -> Endpoint<CreateCustomerResponseDTO> {
        return PaymentCardEndpoints.createCustomer()
    }
    
    /// Get payment methods endpoint
    static func getPaymentMethods() -> Endpoint<PaymentMethodsResponseDTO> {
        return PaymentCardEndpoints.getPaymentMethods()
    }
    
    /// Attach payment method endpoint
    static func attachPaymentMethod(with requestDTO: AttachPaymentMethodRequestDTO) -> Endpoint<AttachPaymentMethodResponseDTO> {
        return PaymentCardEndpoints.attachPaymentMethod(with: requestDTO)
    }
    
    /// Delete payment method endpoint
    static func deletePaymentMethod(id: String) -> Endpoint<DeletePaymentMethodResponseDTO> {
        return PaymentCardEndpoints.deletePaymentMethod(id: id)
    }
    
    /// Set default payment method endpoint
    static func setDefaultPaymentMethod(with requestDTO: SetDefaultPaymentMethodRequestDTO) -> Endpoint<SetDefaultPaymentMethodResponseDTO> {
        return PaymentCardEndpoints.setDefaultPaymentMethod(with: requestDTO)
    }
    
    /// Create payment intent endpoint
    static func createPaymentIntent(with requestDTO: CreatePaymentIntentRequestDTO) -> Endpoint<CreatePaymentIntentResponseDTO> {
        return PaymentCardEndpoints.createPaymentIntent(with: requestDTO)
    }
    
    /// Confirm payment endpoint
    static func confirmPayment(with requestDTO: ConfirmPaymentRequestDTO) -> Endpoint<ConfirmPaymentResponseDTO> {
        return PaymentCardEndpoints.confirmPayment(with: requestDTO)
    }
    
    // MARK: - Order Endpoints
    
    /// Place order endpoint
    static func placeOrder(with requestDTO: PlaceOrderRequestDTO) -> Endpoint<PlaceOrderResponseDTO> {
        return OrderEndpoints.placeOrder(with: requestDTO)
    }
    
    // MARK: - Order Manage Endpoints
    
    /// Get orders endpoint
    static func getOrders() -> Endpoint<OrderManageResponseDTO> {
        return OrderManageEndpoints.getOrders()
    }
    
    // MARK: - Order Detail Endpoints
    
    /// Get order detail endpoint
    static func getOrderDetail(orderId: Int) -> Endpoint<OrderDetailResponseDTO> {
        return OrderDetailEndpoints.getOrderDetail(orderId: orderId)
    }
    
    /// Cancel order endpoint
    static func cancelOrder(orderId: Int) -> Endpoint<CancelOrderResponseDTO> {
        return OrderDetailEndpoints.cancelOrder(orderId: orderId)
    }
}
