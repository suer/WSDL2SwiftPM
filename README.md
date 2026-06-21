WSDL2Swift
==========

Swift alternative to WSDL2ObjC making a SOAP request & parsing its response as defined in WSDL.
Objective-C free.

Stubs for unit test can be implemented using [Toki](https://github.com/banjun/Toki).

## Input & Output

Input

* WSDL 1.1 xmls
* XSD xmls

Output

* a Swift file which works as SOAP client
	* Swift 5
	* NSURLSession for connection
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
let service = TempConvert(endpoint: "http://www.w3schools.com")
service.request(TempConvert_CelsiusToFahrenheit(Celsius: "23.4")).onComplete { r in
    NSLog("%@", "TempConvert_CelsiusToFahrenheit(Celsius: \"23.4\") = \(r)")
}
```

with dependencies:

```swift
.package(url: "https://github.com/suer/WSDL2SwiftPM.git", exact: "x.y.z"),
```

note that pod WSDL2Swift just introduces runtime dependencies. it does not provide WSDL2Swift executable binary nor generated WSDL client Swift files.

sometimes, somewhere in your dependencies chain (transitive framework dependencies or test bundle), header search paths for libxml2 is required. see podspec to add manually.

### Customize

You can specify charset of SOAP request by editing the generated code.

The following code is an example when you want to specify character code to be interpreted as utf-8.

```swift
public var characterSetInContentType: CharacterSetInContentType {
    return .utf8
}
```

By default, `unspecified` is set.

## Example

iOSWSDL2Swift target in xcodeproj is an example using WSDL2Swift.
it generates `WSDL+(ServiceName).swift` at the first step of build and use it from ViewController.swift.

you need to place your WSDL and XSD xmls into exampleWSDLS folder.


## Architecture

usage point of view...

* initialize Service with endpoint URL (endpoint URL can be changed after generating `WSDL+(ServiceName).swift`)
* initialize request parameter with `ServiceName_OperationName(...)`
* `Service.request(param)` to get `Future` that will be completed by `NSURLSession` completion
* parameters and models are typed by xsd definition (even with nullability)

