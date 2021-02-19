//
//  DataRequest.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation

public struct DataRequest: CustomStringConvertible {

    public var urlRequest: URLRequest {
        get {
            switch ref.resource {
            case let .url(url):
                var request = URLRequest(url: url)
                if cachePolicy == .reloadIgnoringCachedData {
                    request.cachePolicy = .reloadIgnoringLocalCacheData
                }
                return request
            case let .urlRequest(urlRequest):
                return urlRequest
            }
        }
        set {
            mutate {
                $0.resource = Resource.urlRequest(newValue)
                $0.urlString = newValue.url?.absoluteString
            }
        }
    }

    var urlString: String? {
        ref.urlString
    }

    public enum Priority: Int, Comparable {
        case veryLow = 0, low, normal, high, veryHigh

        var taskPriority: TaskPriority {
            switch self {
            case .veryLow: return .veryLow
            case .low: return .low
            case .normal: return .normal
            case .high: return .high
            case .veryHigh: return .veryHigh
            }
        }

        public static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public var priority: Priority {
        get { ref.priority }
        set { mutate { $0.priority = newValue } }
    }

    public enum CachePolicy {
        case `default`
        case reloadIgnoringCachedData
    }

    public var cachePolicy: CachePolicy {
        get { ref.cachePolicy }
        set { mutate { $0.cachePolicy = newValue } }
    }

    public var options: ImageRequestOption {
        get { ref.options }
        set { mutate { $0.options = newValue } }
    }

    public var processors: [ImageProcessing] {
        get { ref.processors }
        set { mutate { $0.processors = newValue } }
    }
    
    public init(url: URL,
                processors: [ImageProcessing] = [],
                cachePolicy: CachePolicy = .default,
                priority: Priority = .normal,
                options: ImageRequestOption = .init()) {
        self.ref = Container(resource: Resource.url(url), processors: processors, cachePolicy: cachePolicy, priority: priority, options: options)
        self.ref.urlString = url.absoluteString
    }

    public init(urlRequest: URLRequest,
                processors: [ImageProcessing] = [],
                cachePolicy: CachePolicy = .default,
                priority: DataRequest.Priority = .normal,
                options: ImageRequestOption = .init()) {
        self.ref = Container(resource: Resource.urlRequest(urlRequest), processors: processors, cachePolicy: cachePolicy, priority: priority, options: options)
        self.ref.urlString = urlRequest.url?.absoluteString
    }

    private var ref: Container

    private mutating func mutate(_ closure: (Container) -> Void) {
        if !isKnownUniquelyReferenced(&ref) {
            ref = Container(container: ref)
        }
        closure(ref)
    }

    private class Container {
        var resource: Resource
        var urlString: String?
        var cachePolicy: CachePolicy
        var priority: DataRequest.Priority
        var options: ImageRequestOption
        var processors: [ImageProcessing]

        deinit { }

        init(resource: Resource, processors: [ImageProcessing], cachePolicy: CachePolicy, priority: Priority, options: ImageRequestOption) {
            self.resource = resource
            self.processors = processors
            self.cachePolicy = cachePolicy
            self.priority = priority
            self.options = options
        }

        init(container ref: Container) {
            self.resource = ref.resource
            self.urlString = ref.urlString
            self.processors = ref.processors
            self.cachePolicy = ref.cachePolicy
            self.priority = ref.priority
            self.options = ref.options
        }

        var preferredURLString: String {
            options.filteredURL ?? urlString ?? ""
        }
    }

    private enum Resource: CustomStringConvertible {
        case url(URL)
        case urlRequest(URLRequest)

        var description: String {
            switch self {
            case let .url(url):
                return "\(url)"
            case let .urlRequest(urlRequest):
                return "\(urlRequest)"
            }
        }
    }

    public var description: String {
        return """
        DataRequest {
            resource: \(ref.resource)
            priority: \(ref.priority)
            processors: \(ref.processors)
            options: {
                memoryCacheOptions: \(ref.options.memoryCacheOptions)
                filteredURL: \(String(describing: ref.options.filteredURL))
                cacheKey: \(String(describing: ref.options.cacheKey))
                loadKey: \(String(describing: ref.options.loadKey))
                userInfo: \(String(describing: ref.options.userInfo))
            }
        }
        """
    }
}


public struct ImageRequestOption {

    public struct MemoryCacheOptions {
        public var isReadAllowed = true
        public var isWriteAllowed = true

        public init(isReadAllowed: Bool = true, isWriteAllowed: Bool = true) {
            self.isReadAllowed = isReadAllowed
            self.isWriteAllowed = isWriteAllowed
        }
    }

    public var memoryCacheOptions: MemoryCacheOptions
    public var filteredURL: String?
    public var cacheKey: AnyHashable?
    public var loadKey: AnyHashable?
    public var userInfo: [AnyHashable: Any]

    public init(memoryCacheOptions: MemoryCacheOptions = .init(),
                filteredURL: String? = nil,
                cacheKey: AnyHashable? = nil,
                loadKey: AnyHashable? = nil,
                userInfo: [AnyHashable: Any] = [:]) {
        self.memoryCacheOptions = memoryCacheOptions
        self.filteredURL = filteredURL
        self.cacheKey = cacheKey
        self.loadKey = loadKey
        self.userInfo = userInfo
    }
}

extension DataRequest {

    func makeCacheKeyForFinalImage() -> DataRequest.CacheKey {
        CacheKey(request: self)
    }

   func makeCacheKeyForFinalImageData() -> String {
        "\(ref.preferredURLString)\(ImageProcessors.Composition(processors).identifier)"
    }

    func makeCacheKeyForOriginalImageData() -> String {
        ref.preferredURLString
    }

    func makeLoadKeyForFinalImage() -> LoadKeyForProcessedImage {
        LoadKeyForProcessedImage(
            cacheKey: makeCacheKeyForFinalImage(),
            loadKey: makeLoadKeyForOriginalImage()
        )
    }

    func makeLoadKeyForOriginalImage() -> LoadKeyForOriginalImage {
        LoadKeyForOriginalImage(request: self)
    }

    struct CacheKey: Hashable {
        let request: DataRequest

        func hash(into hasher: inout Hasher) {
            if let customKey = request.ref.options.cacheKey {
                hasher.combine(customKey)
            } else {
                hasher.combine(request.ref.preferredURLString)
            }
        }

        static func == (lhs: CacheKey, rhs: CacheKey) -> Bool {
            let lhs = lhs.request.ref, rhs = rhs.request.ref
            if lhs.options.cacheKey != nil || rhs.options.cacheKey != nil {
                return lhs.options.cacheKey == rhs.options.cacheKey
            }
            return lhs.preferredURLString == rhs.preferredURLString && lhs.processors == rhs.processors
        }
    }

    struct LoadKeyForProcessedImage: Hashable {
        let cacheKey: CacheKey
        let loadKey: AnyHashable
    }

    struct LoadKeyForOriginalImage: Hashable {
        let request: DataRequest

        func hash(into hasher: inout Hasher) {
            if let customKey = request.ref.options.loadKey {
                hasher.combine(customKey)
            } else {
                hasher.combine(request.ref.preferredURLString)
            }
        }

        static func == (lhs: LoadKeyForOriginalImage, rhs: LoadKeyForOriginalImage) -> Bool {
            let (lhs, rhs) = (lhs.request, rhs.request)
            if lhs.options.loadKey != nil || rhs.options.loadKey != nil {
                return lhs.options.loadKey == rhs.options.loadKey
            }
            return Parameters(lhs) == Parameters(rhs)
        }

        private struct Parameters: Hashable {
            let urlString: String?
            let requestCachePolicy: CachePolicy
            let cachePolicy: URLRequest.CachePolicy
            let allowsCellularAccess: Bool

            init(_ request: DataRequest) {
                self.urlString = request.ref.urlString
                self.requestCachePolicy = request.cachePolicy
                switch request.ref.resource {
                case .url:
                    self.cachePolicy = .useProtocolCachePolicy
                    self.allowsCellularAccess = true
                case let .urlRequest(urlRequest):
                    self.cachePolicy = urlRequest.cachePolicy
                    self.allowsCellularAccess = urlRequest.allowsCellularAccess
                }
            }
        }
    }
}


public protocol ImageRequestConvertible {
    func asImageRequest() -> DataRequest
}

extension DataRequest: ImageRequestConvertible {
    public func asImageRequest() -> DataRequest {
        self
    }
}

extension URL: ImageRequestConvertible {
    public func asImageRequest() -> DataRequest {
        DataRequest(url: self)
    }
}

extension URLRequest: ImageRequestConvertible {
    public func asImageRequest() -> DataRequest {
        DataRequest(urlRequest: self)
    }
}
