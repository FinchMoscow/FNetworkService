## Network Service

Is a wrapper around Alamofire


## Getting Started

pod 'FNetworkService'

Network Service supports HTTP request, HTTP request with caching and upload requests.

```
import FNetworkService

let ns = NetworkService()

struct AnyData: Decodable/Codable { /*...*/ }

ns.request(:EndpointProtocol) { [weak self] (result: Result<AnyData>) in
    /*...*/ 
})

```

### Settings

```
FSettings.isDebugPrintEnabled

```

```
var reqSettings = NetworkSettings.default
req.requestTimeout = 2
etc...

NetworkService(settings: reqSettings)

```

### Logs saving

```
class MyLogsSaver: NetworkLogsWriter { /*...*/ } 

NetworkService(logger: NetworkLoggerWriter)

```

### Built With

* [Alamofire](https://github.com/Alamofire/Alamofire)


### Authors

* [Alexandr Antonov](https://github.com/nitrey)


## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
