import AEXML
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
            Toki.removeStub(stub)
        }

        let result = try await service.request(TempConvert_CelsiusToFahrenheit(Celsius: "30"))

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
            Toki.removeStub(stub)
        }

        let result = try await service.request(TempConvert_FahrenheitToCelsius(Fahrenheit: "80"))

        #expect(result.FahrenheitToCelsiusResult == "1234")
    }
}
