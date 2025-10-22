import Foundation

internal typealias NetworkRouterCompletion = (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> ()

protocol NetworkRouter: AnyObject {
    associatedtype EndPointType: EndPoint
    func request(_ route: EndPointType, completion: @escaping NetworkRouterCompletion)
    func cancel()
}

class Router<EndPointType: EndPoint>: NetworkRouter {
    private let session: URLSession
    private let queue = DispatchQueue(label: "com.qiscus.router.queue")

    private var tasks: [URLSessionTask] = []
    private var isRefreshingToken = false
    private var tokenIsInvalid = false
    private let maxRetryCount = 3
    
    private var queuedRequests: [QueuedRequestBox] = []
    private var isRetryingRequests = false
    private var queuedBeforeConfig: [QueuedRequestBox] = []
    private var isRetryingConfigQueue = false
    
    private let configLock = NSLock()
    private var _isConfigLoaded: Bool = QiscusCore.isConfigLoaded
    private var isConfigLoaded: Bool {
        get {
            configLock.lock()
            let value = _isConfigLoaded
            configLock.unlock()
            return value
        }
        set {
            configLock.lock()
            _isConfigLoaded = newValue
            configLock.unlock()
        }
    }
    
    private struct QueuedRequestBox {
        let route: EndPointType
        let retryCount: Int
        let completion: NetworkRouterCompletion
    }

    init(session: URLSession = .shared) {
        self.session = session
        
        // ✅ Register an observer for isConfigLoaded updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConfigLoaded),
            name: NSNotification.Name("QiscusCoreConfigLoaded"),
            object: nil
        )
    }
    
    deinit {
            NotificationCenter.default.removeObserver(self)
    }

    func request(_ route: EndPointType, completion: @escaping NetworkRouterCompletion) {
        queue.async {
            // ✅ Jika config belum selesai diload, antrekan request
            if !self.isConfigLoaded && route.path != "/config" {
                QiscusLogger.debugPrint("[Router] 🕒 Config not loaded, queue request \(route.path)")
                self.queuedBeforeConfig.append(QueuedRequestBox(route: route, retryCount: 0, completion: completion))
                return
            }
            
            
            if self.tokenIsInvalid {
                QiscusLogger.debugPrint("[Router] 🚫 Token is invalid, reject request \(route.path)")
                DispatchQueue.main.async {
                    let error = NSError(domain: "com.qiscus.router", code: 401, userInfo: [
                        NSLocalizedDescriptionKey: "Token is invalid. Please login again."
                    ])
                    completion(nil, nil, error)
                }
                return
            }
            
            if QiscusCore.enableRefreshToken && QiscusCore.enableAutoRefreshToken {
                self.performRequest(route, retryCount: 0, completion: completion)
            } else {
                // If auto-refresh token is disabled or disableExpiredToken, return immediately
                self.performRequestWithoutRefresh(route, completion: completion)
            }
        }
    }

    func cancel() {
        queue.async {
            self.tasks.forEach { $0.cancel() }
            self.tasks.removeAll()
        }
    }
    
    @objc private func handleConfigLoaded() {
        queue.async {
            guard !self.isRetryingConfigQueue else { return }
            self.isConfigLoaded = true

            guard !self.queuedBeforeConfig.isEmpty else {
                QiscusLogger.debugPrint("[Router] ✅ There are no requests queued before config")
                return
            }

            self.isRetryingConfigQueue = true
            let queued = self.queuedBeforeConfig
            self.queuedBeforeConfig.removeAll()

            QiscusLogger.debugPrint("[Router] 🔁 Config finished loading, retry \(queued.count) request")
            let group = DispatchGroup()
            for req in queued {
                group.enter()
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                    self.performRequest(req.route, retryCount: req.retryCount) { data, response, error in
                        req.completion(data, response, error)
                        group.leave()
                    }
                }
            }

            group.notify(queue: self.queue) {
                self.isRetryingConfigQueue = false
                QiscusLogger.debugPrint("[Router] ✅ Finish retrying all requests before config")
            }
        }
    }

    private func performRequest(
        _ route: EndPointType,
        retryCount: Int,
        completion: @escaping NetworkRouterCompletion
    ) {
        do {
            let request = try buildRequest(from: route)
            QiscusLogger.debugPrint("[Router] ▶️ Request: \(route.path) retryCount: \(retryCount)")

            var task: URLSessionTask!
            task = session.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }

                self.queue.async {
                    self.tasks.removeAll { $0 == task }
                }

                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                QiscusLogger.debugPrint("[Router] ⬅️ Response: \(route.path) status: \(statusCode)")

                guard let httpResponse = response as? HTTPURLResponse else {
                    DispatchQueue.main.async { completion(data, response, error) }
                    return
                }

                var isAuthError = false
                var isTokenExpired = false
                var isUnauthorized = false

                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    isAuthError = true
                    if let d = data,
                       let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                       let err = json["error"] as? [String: Any],
                       let msg = err["message"] as? String,
                       msg.lowercased() == "unauthorized. token is expired" {
                        isTokenExpired = true
                    }
                    
                    if let d = data,
                       let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                       let err = json["error"] as? [String: Any],
                       let msg = err["message"] as? String,
                       msg.lowercased() == "unauthorized" {
                        isUnauthorized = true
                        if let delegate = QiscusCore.delegate {
                            DispatchQueue.main.async {
                                delegate.onRefreshToken(event: .isUnauthorized)
                            }
                        }
                    }
                }

                if isAuthError && !route.path.contains("refresh_user_token") {
                    QiscusLogger.debugPrint("[Router] ⚠️ \(route.path) auth error → enqueue")
                    self.enqueueRequest(route: route, retryCount: retryCount, completion: completion)

                    if isTokenExpired && httpResponse.statusCode == 403 && isUnauthorized == false {
                        self.triggerTokenRefreshIfNeeded()
                    } else if httpResponse.statusCode == 401 {
                        QiscusLogger.debugPrint("[Router] 🚦 401 received, probably race condition → wait for refresh")
                        QiscusCore.maxErrorCountInvalidToken += 1
                        if QiscusCore.maxErrorCountInvalidToken == 10 {
                            if let delegate = QiscusCore.delegate {
                                //need to force logout & login (race condition)
                                delegate.onRefreshToken(event: QiscusRefreshTokenEvent.isUnauthorized)
                            }
                        }
                    }
                    
                    if isUnauthorized == false {
                        return
                    }
                }else if httpResponse.statusCode == 401{
                    QiscusLogger.debugPrint("[Router] 🚦 \(httpResponse.statusCode) received, probably race condition")
                    QiscusCore.maxErrorCountInvalidToken += 1
                    if QiscusCore.maxErrorCountInvalidToken == 10 {
                        if let delegate = QiscusCore.delegate {
                            //need to force logout & login (race condition)
                            delegate.onRefreshToken(event: QiscusRefreshTokenEvent.isUnauthorized)
                        }
                    }
                }

                if let nsError = error as NSError?,
                   nsError.domain == NSURLErrorDomain,
                   nsError.code == NSURLErrorTimedOut,
                   retryCount < self.maxRetryCount {
                    QiscusLogger.debugPrint("[Router] ⏳ Timeout → retry \(retryCount + 1)/\(self.maxRetryCount)")
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                        self.performRequest(route, retryCount: retryCount + 1, completion: completion)
                    }
                    return
                }

                DispatchQueue.main.async { completion(data, response, error) }
            }

            queue.async {
                self.tasks.append(task)
            }
            task.resume()

        } catch {
            DispatchQueue.main.async { completion(nil, nil, error) }
        }
    }

    private func performRequestWithoutRefresh(
        _ route: EndPointType,
        completion: @escaping NetworkRouterCompletion
    ) {
        do {
            let request = try buildRequest(from: route)
            QiscusLogger.debugPrint("[Router] ▶️ Request: \(route.path)")

            var task: URLSessionTask!
            task = session.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                QiscusLogger.debugPrint("[Router] ⬅️ Response: \(route.path) status: \(statusCode)")

                if let delegate = QiscusCore.delegate {
                    if statusCode == 403 {
                        if let d = data,
                           let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                           let err = json["error"] as? [String: Any],
                           let msg = err["message"] as? String,
                           msg.lowercased() == "unauthorized. token is expired" {
                            DispatchQueue.main.async {
                                delegate.onRefreshToken(event: .isTokenExpired)
                            }
                            
                        }
                        
                        if let d = data,
                           let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                           let err = json["error"] as? [String: Any],
                           let msg = err["message"] as? String,
                           msg.lowercased() == "unauthorized" {
                            DispatchQueue.main.async {
                                delegate.onRefreshToken(event: .isUnauthorized)
                            }
                            
                        }
                    }
                }
                
                DispatchQueue.main.async { completion(data, response, error) }
            }

            queue.async {
                self.tasks.append(task)
            }
            task.resume()

        } catch {
            DispatchQueue.main.async { completion(nil, nil, error) }
        }
    }

    private func enqueueRequest(route: EndPointType, retryCount: Int, completion: @escaping NetworkRouterCompletion) {
        queue.sync {
            if self.tokenIsInvalid {
                QiscusLogger.debugPrint("[Router] 🚫 Token is invalid, reject request \(route.path)")
                DispatchQueue.main.async {
                    let error = NSError(domain: "com.qiscus.router", code: 401, userInfo: [
                        NSLocalizedDescriptionKey: "Token is invalid. Please login again."
                    ])
                    completion(nil, nil, error)
                }
                return
            }

            let requestBox = QueuedRequestBox(route: route, retryCount: retryCount, completion: completion)
            self.queuedRequests.append(requestBox)
            QiscusLogger.debugPrint("[Router] 🕒 Enqueued \(route.path). Queue count: \(self.queuedRequests.count)")

            self.triggerTokenRefreshIfNeeded()
        }
    }

    private func triggerTokenRefreshIfNeeded() {
        queue.async {
            if self.isRefreshingToken || self.isRetryingRequests {
                QiscusLogger.debugPrint("[Router] ⏳ Refresh or retry already in progress → skip")
                return
            }

            guard !self.queuedRequests.isEmpty else {
                QiscusLogger.debugPrint("[Router] 🔄 No queued requests, skip refresh")
                return
            }

            self.isRefreshingToken = true
            QiscusLogger.debugPrint("[Router] 🔄 Starting token refresh...")

            self.refreshToken { success in
                self.queue.async {
                    self.isRefreshingToken = false

                    if !success {
                        QiscusLogger.debugPrint("[Router] ⚠️ Refresh failed, cancelling \(self.queuedRequests.count) queued requests")
                        self.tokenIsInvalid = true
                        for req in self.queuedRequests {
                            DispatchQueue.main.async {
                                let error = NSError(domain: "com.qiscus.router", code: 401, userInfo: [
                                    NSLocalizedDescriptionKey: "Token refresh failed. Request cancelled."
                                ])
                                req.completion(nil, nil, error)
                            }
                        }
                        self.queuedRequests.removeAll()
                        return
                    }

                    self.tokenIsInvalid = false

                    guard !self.queuedRequests.isEmpty else {
                        QiscusLogger.debugPrint("[Router] 🔁 No queued requests after refresh")
                        return
                    }

                    self.isRetryingRequests = true
                    let queued = self.queuedRequests
                    self.queuedRequests.removeAll()

                    QiscusLogger.debugPrint("[Router] 🔁 Retrying \(queued.count) queued requests")
                    QiscusLogger.debugPrint("[Router] 🔁 Will retry routes: \(queued.map { $0.route.path })")

                    let group = DispatchGroup()
                    for req in queued {
                        let route = req.route
                        group.enter()
                        QiscusLogger.debugPrint("[Router] 🔁 Retrying queued request: \(route.path) retryCount \(req.retryCount + 1)")
                        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                            self.performRequest(route, retryCount: req.retryCount + 1) { data, response, error in
                                req.completion(data, response, error)
                                group.leave()
                            }
                        }
                    }

                    group.notify(queue: self.queue) {
                        self.isRetryingRequests = false
                        QiscusLogger.debugPrint("[Router] 🔁 Finished retrying queued requests")
                        if !self.queuedRequests.isEmpty {
                            QiscusLogger.debugPrint("[Router] 🔄 New requests enqueued during retry → trigger refresh again")
                            self.triggerTokenRefreshIfNeeded()
                        }
                    }
                }
            }
        }
    }

    private func refreshToken(completion: @escaping (Bool) -> Void) {
        QiscusCore.shared.autoRefreshToken { success in
            QiscusLogger.debugPrint("[Router] 🔄 refreshToken success: \(success)")
            if let delegate = QiscusCore.delegate {
                delegate.onRefreshToken(event: .isSuccessAutoRefreshToken)
            }
            completion(success)
        } onError: { error in
            QiscusLogger.debugPrint("[Router] ❌ refreshToken error: \(error.message)")
            if error.message.lowercased() == "refresh token invalid" {
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    // MARK: - Request Builder
    private func buildRequest(from route: EndPointType) throws -> URLRequest {
        var request = URLRequest(
            url: route.baseURL.appendingPathComponent(route.path),
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 10.0
        )
        request.httpMethod = route.httpMethod.rawValue

        if let headers = route.header {
            addAdditionalHeaders(headers, request: &request)
        }

        switch route.task {
        case .request:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        case .requestParameters(let bodyParameters, let encoding, let urlParameters):
            try configureParameters(bodyParameters: bodyParameters,
                                    bodyEncoding: encoding,
                                    urlParameters: urlParameters,
                                    request: &request)

        case .requestParametersAndHeaders(let bodyParameters, let encoding, let urlParameters, let headers):
            addAdditionalHeaders(headers, request: &request)
            try configureParameters(bodyParameters: bodyParameters,
                                    bodyEncoding: encoding,
                                    urlParameters: urlParameters,
                                    request: &request)

        case .requestCompositeParameters(let bodyParameters, let bodyEncoding, let urlParameters):
            try configureParameters(bodyParameters: bodyParameters,
                                    bodyEncoding: bodyEncoding,
                                    urlParameters: urlParameters,
                                    request: &request)
        }

        return request
    }

    private func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?, request: inout URLRequest) {
        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    private func configureParameters(bodyParameters: Parameters?,
                                     bodyEncoding: ParameterEncoding,
                                     urlParameters: Parameters?,
                                     request: inout URLRequest) throws {
        try bodyEncoding.encode(urlRequest: &request,
                                bodyParameters: bodyParameters,
                                urlParameters: urlParameters)
    }
}
