public struct SabilAppearanceConfig {
    let locale: String
}

public struct SabilLimitConfig {
    let mobileLimit: Int
    let overallLimit: Int
}

public final class Sabil {
    let clientID: String
    let secret: String?
    let userID: String
    let appearanceConfig: SabilAppearanceConfig
    let limitConfig: SabilLimitConfig
    
    internal init(clientID: String, secret: String?, userID: String, appearanceConfig: SabilAppearanceConfig, limitConfig: SabilLimitConfig) {
        self.clientID = clientID
        self.secret = secret
        self.userID = userID
        self.appearanceConfig = appearanceConfig
        self.limitConfig = limitConfig
    }
}
