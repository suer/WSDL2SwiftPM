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

### Using SPM Build Plugin

`WSDL2SwiftPMPlugin` automatically generates Swift client code from WSDL files at build time.

Add the plugin to your `Package.swift`:

```swift
// in dependencies:
.package(url: "https://github.com/suer/WSDL2SwiftPM.git", exact: "x.y.z"),

// in targets:
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "WSDL2SwiftPM", package: "WSDL2SwiftPM"),
    ],
    plugins: [
        .plugin(name: "WSDL2SwiftPMPlugin", package: "WSDL2SwiftPM"),
    ]
),
```

#### Auto-detection mode

Place `.wsdl` or `.xsd` files in the target's Sources directory. The plugin detects them automatically — no configuration file needed.

```
Sources/YourTarget/YourService.wsdl
```

#### Configuration with `wsdl2swift.json`

For more control, place a `wsdl2swift.json` at the package root or inside the target's Sources directory:

```json
{
  "inputs": [
    "./Sources/YourTarget/your.wsdl"
  ],
  "output": "${DERIVED_SOURCES_DIR}/WSDL.swift",
  "publicMemberwiseInit": true
}
```

| Key | Type | Description |
|-----|------|-------------|
| `inputs` | `[String]` | Paths to input files, relative to the config file. Any file extension is accepted. Omit to use auto-detection. |
| `output` | `String` | Output directory path. The filename portion is ignored — generated files are always named `WSDL+<ServiceName>.swift`. Supports variable substitution. |
| `publicMemberwiseInit` | `Bool` | Generate `public` memberwise initializers. Required when the target is imported from another module. Default: `true`. |

The following variables can be used in string values:

| Variable | Value |
|----------|-------|
| `${DERIVED_SOURCES_DIR}` | Plugin's output directory |
| `${PROJECT_DIR}` | Package root directory |
| `${TARGET_NAME}` | Target name |
| `${PRODUCT_MODULE_NAME}` | Module name |

#### Generated output

The plugin generates `WSDL+<ServiceName>.swift` in the plugin's work directory. The file is compiled automatically as part of the target.

### Use In App

add WSDL.swift to your project and use:
(note that service type name and requeest type name are vary, depending on source WSDL)

generated code from example by w3schools temperature converter:

```swift
public struct TempConvert: WSDLService {
	:
    public func request(_ parameters: TempConvert_CelsiusToFahrenheit) async throws -> TempConvert_CelsiusToFahrenheitResponse {
        return try await requestGeneric(parameters)
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
let result = try await service.request(TempConvert_CelsiusToFahrenheit(Celsius: "23.4"))
```

with dependencies in `Package.swift`:

```swift
// in dependencies:
.package(url: "https://github.com/suer/WSDL2SwiftPM.git", exact: "x.y.z"),

// in targets:
.target(
    name: "YourTarget",
    dependencies: [
        "WSDL2SwiftPM",
    ]
),
```

note that WSDL2SwiftPM just introduces runtime dependencies. it does not provide WSDL2SwiftPMCLI executable binary nor generated WSDL client Swift files.

### Testing with stubs

Toki provides HTTP stub functionality for testing WSDL services using [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs).

Add Toki to your test target in `Package.swift`:

```swift
.testTarget(
    name: "YourTests",
    dependencies: [
        "WSDL2SwiftPM",
        .product(name: "Toki", package: "WSDL2SwiftPM"),
    ]
),
```

In your test file, conform the service to `WSDLServiceStubbable` and add the `soapRequest` helper:

```swift
import Toki
import AEXML

extension YourService: WSDLServiceStubbable {}
extension WSDLService {
    public func soapRequest<R: XSDType>(_ response: R, _ tns: String) -> AEXMLDocument {
        return response.soapRequest(tns)
    }
}
```

Then stub requests in your tests:

```swift
let service = YourService(endpoint: "http://localhost/")

let stub = Toki.stub(
    service,
    YourService_RequestType.self,
    YourService_ResponseType(someField: "mocked value")
)
defer { Toki.removeStub(stub) }

let result = try await service.request(YourService_RequestType())
```

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
* `try await Service.request(param)` to get response completed by `URLSession`
* parameters and models are typed by xsd definition (even with nullability)

