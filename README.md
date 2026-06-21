WSDL2SwiftPM
============

Swift alternative to WSDL2ObjC making a SOAP request & parsing its response as defined in WSDL.
Objective-C free.

This repository is a fork of [banjun/WSDL2Swift](https://github.com/banjun/WSDL2Swift), a Swift Package Manager port, and merges [banjun/Toki](https://github.com/banjun/Toki) for test stub functionality.

## Input & Output

Input

* WSDL 1.1 xmls
* XSD xmls

Output

* a Swift file which works as SOAP client
	* Swift 5
	* URLSession for connection
	* [BrightFutures](https://github.com/Thomvis/BrightFutures) for returning asynchronous requests
	* [Fuzi](https://github.com/cezheng/Fuzi) for fast parsing xmls
	* [AEXML](https://github.com/tadija/AEXML) for generating xmls

## Usage

### Build

```sh
swift build
```

### Generate

generate WSDL.swift from WSDL and XSD xmls:

```sh
swift run WSDL2SwiftPMCLI --public-memberwise-init --out Tests/WSDL2SwiftPMTests/WSDL.swift Tests/tempconvert.xml
```

the order of input files is important.
referenced XSDs should be placed immediately after referencing WSDL.

### Use In App

add WSDL.swift to your project and use:
(note that service type name and requeest type name are vary, depending on source WSDL)

generated code from example by w3schools temperature converter:

```swift
public struct TempConvert: WSDLService {
	:
    public func request(_ parameters: TempConvert_CelsiusToFahrenheit) -> Future<TempConvert_CelsiusToFahrenheitResponse, WSDLOperationError> {
        return requestGeneric(parameters)
    }
    :
}

:

public struct TempConvert_CelsiusToFahrenheit {
    public var Celsius: String?
}

public struct TempConvert_CelsiusToFahrenheitResponse {
    public var CelsiusToFahrenheitResult: String?
}

:
(continued...)
```

code using the generated client:

```swift
let service = TempConvert(endpoint: "https://www.w3schools.com")
service.request(TempConvert_CelsiusToFahrenheit(Celsius: "23.4")).onComplete { r in
    NSLog("%@", "TempConvert_CelsiusToFahrenheit(Celsius: \"23.4\") = \(r)")
}
```

with dependencies in `Package.swift`:

```swift
// in dependencies:
.package(url: "https://github.com/suer/WSDL2SwiftPM.git", exact: "x.y.z"),

// in targets:
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "WSDL2SwiftPM", package: "WSDL2SwiftPM"),
    ]
),
```

note that WSDL2SwiftPM just introduces runtime dependencies. it does not provide WSDL2SwiftPMCLI executable binary nor generated WSDL client Swift files.

### Customize

You can specify charset of SOAP request by editing the generated code.

The following code is an example when you want to specify character code to be interpreted as utf-8.

```swift
public var characterSetInContentType: CharacterSetInContentType {
    return .utf8
}
```

By default, `unspecified` is set.

## Architecture

usage point of view...

* initialize Service with endpoint URL (endpoint URL can be changed after generating `WSDL+(ServiceName).swift`)
* initialize request parameter with `ServiceName_OperationName(...)`
* `Service.request(param)` to get `Future` that will be completed by `URLSession` completion
* parameters and models are typed by xsd definition (even with nullability)

