import AEXML
import OHHTTPStubs
import Testing
import Toki
import WSDL2SwiftPM

extension TempConvert: WSDLServiceStubbable {}
extension WSDLService {
    public func soapRequest<R: XSDType>(_ response: R, _ tns: String) -> AEXMLDocument {
        return response.soapRequest(tns)
    }
}

struct TempConvertTests {
    let service = TempConvert(endpoint: "http://localhost/")

    @Test("C to F")
    func testCelsiusToFahrenheit() async throws {
        let stub = Toki.stub(
            service,
            TempConvert_CelsiusToFahrenheit.self,
            TempConvert_CelsiusToFahrenheitResponse(CelsiusToFahrenheitResult: "999")
        )
        defer {
            HTTPStubs.removeStub(stub)
        }

        let future = service.request(TempConvert_CelsiusToFahrenheit(Celsius: "30"))

        let result = try await future.get()

        #expect(result.CelsiusToFahrenheitResult == "999")
    }

    @Test("F to C")
    func testFahrenheitToCelsius() async throws {
        let stub = Toki.stub(
            service,
            TempConvert_FahrenheitToCelsius.self,
            TempConvert_FahrenheitToCelsiusResponse(FahrenheitToCelsiusResult: "1234")
        )
        defer {
            HTTPStubs.removeStub(stub)
        }

        let future = service.request(TempConvert_FahrenheitToCelsius(Fahrenheit: "80"))

        let result = try await future.get()

        #expect(result.FahrenheitToCelsiusResult == "1234")
    }
}
