## Network Service

Is a wrapper around Alamofire


## Getting Started

pod 'FNetworkService'

```
import FNetworkService

NetworkService().request(endpoint: EndpointProtocol, completion: (Result<Decodable & Encodable>) -> Void)
NetworkService().request(endpoint: EndpointProtocol, cachingEnabled: Bool, completion: (Result<Decodable & Encodable>) -> Void)

```

### Settings

```
AdditionalSettings.isResponsePrintEnabled
AdditionalSettings.isStatusCodePrintEnabled

```

```
var reqSettings = NetworkSettings.default
req.requestTimeout = 2
etc...

NetworkService(settings: reqSettings)

```

### Logs saving

```
class MyLogsSaver: NetworkLoggerWriter { /*...*/ } 

NetworkService(logger: NetworkLoggerWriter)

```

### Built With

* [Alamofire](https://github.com/Alamofire/Alamofire)


### Authors

* [Alexandr Antonov](https://github.com/nitrey)
* [Eugene Orekhin](https://github.com/ffs14k)


## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
