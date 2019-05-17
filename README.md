### Features

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
5. [Built With](#Built-With)
6. [Built With](#Built-With)
7. [Authors](#Authors)
8. [License](#License)




### Usage

```
struct AnyResponse: Decodable/Codable { /*...*/ }
```

```
let networkService = NetworkService()
networkService.request(endpoint: EndpointProtocol, completion: <(Result<Decodable, APIError>) -> Void>)
```

Use `public typealias APIResult<Model> = Swift.Result<Model, APIError>` in a completion block in order to explicitly specify Codable Type

```
networkService.request(endpoint: EndpointProtocol) { [weak self] (result: APIResult<AnyResponse>) in
}
```


### Settings

Set up project settings which will be used by every NetworkService's instance
```
NetworkService.Settings.defaultLogger: NetworkLogsWriter? // nil by default
NetworkService.Settings.defaultDebugLogger: NetworkLogWriter // DebugLogWriter by default
```

Set up settings appropriately for NetworkService instance
```
var settings: NetworkService.Setting = .default
settings.validCodes: Range<Int>
settings.cacheRequestTimeout: TimeInterval
settings.requestTimeout: TimeInterval
settings.dateDecodingStrategy: JSONDecoder.DateDecodingStrategy
settings.networkLogger: NetworkLogsWriter?
settings.debugLogger: NetworkLogWriter

let configuratedNetworkService = NetworkService(settings: settings)
```


### Log Writer

Change debug logger behaviour

```
NetworkService.Settings.defaultDebugLogger.writeOptions = .none
```

Implement logs writer for your purposes.

```
class MyLogWriter: NetworkLogsWriter {
    var writeOptions: LoggerWriteOptions { get set }
    func write(log: String)
    
    // With default implemetation
    var dateLocale: Locale { get } // default is "en_US"
    func write<T>(endpoint: EndpointProtocol, result: APIResult<T>)
}

NetworkService.Settings.networkLogger = MyLogWriter()
NetworkService.Settings.debugLogger = MyLogWriter()
```


### Constructing Endpoints

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
        case .main:             return ""
        case .search(let path): return path
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
### Built With

* [Alamofire](https://github.com/Alamofire/Alamofire)

### Authors

FNetworkService is developed by <a href="https://github.com/nitrey">Alexandr Antonov</a>. Extended and deployed by <a href="https://github.com/ffs14k"> Eugene Orekhin</a>.


### License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
