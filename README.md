### Features

- Flexible
- Closure API
- Codable/Decodable response
- Soft to construct requests

###### Supports
- HTTP request;
- HTTP request with response caching;
- Upload HTTP requests

**Table of Contents**

1. [Usage](#Usage)
2. [Settings](#Settings)
3. [Log Writer](#Log-Writer)
4. [Constructing Endpoints](#Constructing-Endpoints)
5. [Extending NetworkService](#Extending-NetworkService)
6. [Substitution](#Substitution)
7. [Typealiases](#Typealiases)
8. [Built With](#Built-With)
9. [Authors](#Authors)
10. [License](#License)




### Usage

> pod 'FNetworkService'


```
struct AnyResponse: Decodable/Codable { /*...*/ }
```

```
let networkService = NetworkService()
networkService.request(endpoint: EndpointProtocol, completion: <(Result<Decodable, APIError>) -> Void>)
```

Use `public typealias APIResult<Model> = Swift.Result<Model, APIError>` in a completion block in order to explicitly specify Codable Type

```
networkService.request(endpoint: EndpointProtocol) { [weak self] (result: APIResult<Data>) in
    // handle response
}
        
networkService.request(endpoint: EndpointProtocol, isCahingEnabled: Bool) { [weak self] (result: APIResult<AnyResponse>) in
    // handle response
}
        
networkService.request(endpoint: EndpointProtocol, isCahingEnabled: Bool) { ([weak self] (result: APIXResult<AnyResponse>) in
    // handle response
}
```


### Settings

Settings which will be used by **each** NetworkService's instance
```
NetworkService.Settings.defaultLogger: NetworkLogsWriter? // DebugLogWriter by default
NetworkService.Settings.defaultRequestSettings: RequestSettingsProtocol //  RequestSettings by default. It contains additionalHeaders which is nil by default. They will be merged with Endpoint's headers, if set.
```

Setting up NetworkService instance
```
let settings: NetworkService.Setting = .default
settings.validCodes: Range<Int> = ..                                    // (200 ..< 300) by default
settings.cacheRequestTimeout: TimeInterval = ...                        // 0.3 by default
settings.requestTimeout: TimeInterval = ...                             // 10 by default
settings.completionQueue: DispatchQueue = ...                           // .main by default
settings.dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = ...   // JSONDecoder.DateDecodingStrategy.millisecondsSince1970 by default
settings.requestSettings: RequestSettingsProtocol = ...                 // Settings.defaultRequestSettings by default
settings.networkLogger: NetworkLogsWriter? = ...                        // Settings.defaultLogger by default

let configuratedNetworkService = NetworkService(settings: settings)
```


### Log Writer

Change debug logger behaviour

```
// .all by default
// Options: .none; .onSuccess; .onError; .all
NetworkService.Settings.defaultDebugLogger.writeOptions = .none
```

Implement logs writer for your purposes

```
class MyLogWriter: NetworkLogsWriter {
    var writeOptions: LoggerWriteOptions { get set }
    func write(log: String)
    
    // With default implemetation
    var dateLocale: Locale { get } // default is "en_US"
    func write<T>(endpoint: EndpointProtocol, result: APIResult<T>)
}

NetworkService.Settings.networkLogger = MyLogWriter()
```


### Constructing Endpoints

`struct example`

```
struct ProfileEnpoint: EndpointProtocol {

    init(id: String) { self.id = id }

    let baseUrl: URL? = URL(string: "https://www.myprofile.com/")
    let path: String = "pofile"
    let method: HTTPMethod = .get
    let parameters: Parameters? = ["id": id]
}
```

`enum example`
```
enum GoogleEndpoint: EndpointProtocol {
    case main
    case search(path: String)
    
    var baseUrl: URL? { return URL(string: "https://www.google.com/") }
    var method: HTTPMethod { return .get  }
    var parameters: Parameters? { return nil }
    
    var path: String {
        switch self {
        case .main:              return ""
        case .search(let path):  return path
        }
    }
    
}
```
`EndpointProtocol default properties, see a code for details`
```
var encoding: ParameterEncoding
var headers: HTTPHeaders?
var cacheKey: String?
```

### Extending NetworkService

```
class MyNetworkService: NetworkService

    init(settings: NetworkService.Settings = Settings.default) {
        
        settings.requestSettings.additionalHeaders = ["MyHeaderKey": "MyheaderValue"]
        
        if (debug) {
            settings.debugLogger?.writeOptions = .none
        }
        
        super.init(settings: settings)
    }
    
    override func request(endpoint: EndpointProtocol, completion: @escaping (APIResult<Data>) -> Void) {
        myUsefulMethod()
        super.request(endpoint: endpoint, completion: completion)
    }
    
    // triggers after response comes
    override func parse(response: DefaultDataResponse, forEndpoint endpoint: EndpointProtocol) -> APIResult<Data> {
        anotherUsefulMethod()
        return super.parse(response: response, forEndpoint: endpoint)
    }

```

### Substitution

```
var networkService: NetworkServiceProtocol = NetworkService()
networkService = MyNetworkService()
```


### Typealiases

```
public typealias NetworkServiceProtocol = NetworkRequestable & ResponseParser

public typealias Parameters = [String: Any]
public typealias HTTPHeaders = [String: String]
public typealias HTTPMethod = Alamofire.HTTPMethod

public typealias APIResult<Model> = Swift.Result<Model, APIError>
public typealias APIXResult<Model> = Swift.Result<ModelWithResponse<Model>, APIError>

```

### Built With

* [Alamofire](https://github.com/Alamofire/Alamofire)

### Authors

FNetworkService is developed by <a href="https://github.com/nitrey">Alexandr Antonov</a>. Extended and deployed by <a href="https://github.com/ffs14k"> Eugene Orekhin</a>.


### License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
