### Features

- HTTP request;
- HTTP request with response caching;
- Upload HTTP requests;

**Table of Contents**

[TOC]


###Usage

```
struct AnyResponse: Decodable/Codable { /*...*/ }
```

```
let networkService = NetworkService()
networkService.request(endpoint: EndpointProtocol, completion: <(Result<Decodable, APIError>) -> Void>)
```

Use `public typealias APIResult<Model> = Swift.Result<Model, APIError>` in a completion block

```
networkService.request(endpoint: EndpointProtocol) { [weak self] (result: AnyResponse) in
}
```


###Settings

Set up project settings which will be used by every NetworkService instance
```
NetworkService.Settings.defaultLogger: NetworkLogsWriter? // nil by default
public static var defaultDebugLogger: NetworkLogWriter? // DebugLogWriter by default
```

Set up settings appropriately for NetworkService instance
```
var settings: NetworkService.Setting = .default
settings.validCodes: Range<Int>
settings.cacheRequestTimeout: TimeInterval
settings.requestTimeout: TimeInterval
settings.dateDecodingStrategy: JSONDecoder.DateDecodingStrategy
settings.networkLogger: NetworkLogsWriter?
settings.debugLogger: NetworkLogWriter?

let configuratedNetworkService = NetworkService(settings: settings)
```


###Logs Writer

Implement logs writer for your purposes.

```
class MyLogsWriter: NetworkLogsWriter {
    var writeOptions: LoggerWriteOptions { get }
    func write(log: String)
    
    // With default implemetation
    var dateLocale: Locale { get } // default is "en_US"
    func write<T>(endpoint: EndpointProtocol, result: APIResult<T>)
}
```


###Constructing Endpoints

`struct example`

```
struct GoogleEndpoint: EndpointProtocol {
    var baseUrl: URL? = URL(string: "https://www.google.com/")
    var path: String = ""
    var method: HTTPMethod = .get
    var parameters: Parameters? = nil
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
        case .main:                 return ""
        case .search(let path): return path
        }
    }
    
}
```

### Built With

* [Alamofire](https://github.com/Alamofire/Alamofire)


### Authors

FNetworkService is developed by <a href="https://github.com/nitrey">Alexandr Antonov</a>. Extended and deployed by <a href="https://github.com/nitrey"> Eugene Orekhin</a>.


### License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
