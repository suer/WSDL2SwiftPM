import AEXML
import Fuzi
import OHHTTPStubs  // see https://github.com/AliSoftware/OHHTTPStubs/wiki/Testing-for-the-request-body-in-your-stubs
import WSDL2SwiftPM
import XCTest

// all WSDLServices in test should conform to this protocol, declared in the test target
public protocol WSDLServiceStubbable {
    var endpoint: String { get set }
    var path: String { get }
    var targetNamespace: String { get }
    // this should be implemented by the test target (using @testable import the app target)
    func soapRequest<R: XSDType>(_ response: R, _ tns: String) -> AEXMLDocument
}

public enum Toki {
    @discardableResult
    public static func stub<S: WSDLServiceStubbable, T: XSDType, R: XSDType>(
        _ service: S, _ type: T.Type, _ response: R,
        requestDataModifier: @escaping (Data) -> Data = { $0 },
        responseDataModifier: @escaping (Data) -> Data = { $0 }
    ) -> HTTPStubsDescriptor {
        return HTTPStubs.stubRequests(
            passingTest: service.stubMatcher(type, dataModifier: requestDataModifier),
            withStubResponse: service.stubBuilder(response, dataModifier: responseDataModifier))
    }

    @discardableResult
    public static func stub<S: WSDLServiceStubbable, T: XSDType & ExpressibleByXML, R: XSDType>(
        _ service: S, requestMatcher: @escaping (T) -> Bool, _ response: R,
        requestDataModifier: @escaping (Data) -> Data = { $0 },
        responseDataModifier: @escaping (Data) -> Data = { $0 }
    ) -> HTTPStubsDescriptor {
        return HTTPStubs.stubRequests(
            passingTest: service.stubMatcher(
                requestMatcher: requestMatcher, dataModifier: requestDataModifier),
            withStubResponse: service.stubBuilder(response, dataModifier: responseDataModifier))
    }

    @discardableResult
    public static func stub<S: WSDLServiceStubbable, T: XSDType & ExpressibleByXML>(
        _ service: S, requestMatcher: @escaping (T) -> Bool, _ response: Data,
        requestDataModifier: @escaping (Data) -> Data = { $0 }
    ) -> HTTPStubsDescriptor {
        return HTTPStubs.stubRequests(
            passingTest: service.stubMatcher(
                requestMatcher: requestMatcher, dataModifier: requestDataModifier),
            withStubResponse: service.stubBuilder(response))
    }

    public static func removeStub(_ stub: HTTPStubsDescriptor) {
        HTTPStubs.removeStub(stub)
    }
}

// extension for stub request and response in WSDLService
extension XCTest {
    @discardableResult
    public func stub<S: WSDLServiceStubbable, T: XSDType, R: XSDType>(
        _ service: S, _ type: T.Type, _ response: R,
        requestDataModifier: @escaping (Data) -> Data = { $0 },
        responseDataModifier: @escaping (Data) -> Data = { $0 }
    ) -> HTTPStubsDescriptor {
        return Toki.stub(
            service, type, response,
            requestDataModifier: requestDataModifier,
            responseDataModifier: responseDataModifier)
    }

    @discardableResult
    public func stub<S: WSDLServiceStubbable, T: XSDType & ExpressibleByXML, R: XSDType>(
        _ service: S, requestMatcher: @escaping (T) -> Bool, _ response: R,
        requestDataModifier: @escaping (Data) -> Data = { $0 },
        responseDataModifier: @escaping (Data) -> Data = { $0 }
    ) -> HTTPStubsDescriptor {
        return Toki.stub(
            service, requestMatcher: requestMatcher, response,
            requestDataModifier: requestDataModifier,
            responseDataModifier: responseDataModifier)
    }

    @discardableResult
    public func stub<S: WSDLServiceStubbable, T: XSDType & ExpressibleByXML>(
        _ service: S, requestMatcher: @escaping (T) -> Bool, _ response: Data,
        requestDataModifier: @escaping (Data) -> Data = { $0 }
    ) -> HTTPStubsDescriptor {
        return Toki.stub(
            service, requestMatcher: requestMatcher, response,
            requestDataModifier: requestDataModifier)
    }
}

private let optionsForNamespaceRemoving: AEXMLOptions = {
    var options = AEXMLOptions()
    options.parserSettings.shouldProcessNamespaces = true
    options.parserSettings.shouldReportNamespacePrefixes = false
    return options
}()

extension WSDLServiceStubbable {
    public func stubMatcher<T: XSDType>(
        _ type: T.Type,
        dataModifier: @escaping (Data) -> Data = { $0 }
    ) -> HTTPStubsTestBlock {
        return { request in
            guard let requestUrl = request.url else { return false }

            if let url = URL(string: self.endpoint + self.path), url.scheme != nil {
                // self.endpoint is an absolute url
                if requestUrl.absoluteString != url.absoluteString {
                    return false
                }
            } else {
                // self.endpoint is a path
                if requestUrl.path != self.endpoint + self.path {
                    return false
                }
            }

            guard let data = (request as NSURLRequest).ohhttpStubs_HTTPBody().map(dataModifier),
                let xml = try? AEXMLDocument(xml: data, options: optionsForNamespaceRemoving)
            else { return false }

            let typeName = String(describing: type)
            let typeSuffix = typeName.components(separatedBy: "_").last ?? typeName

            return xml["Envelope"]["Body"][typeSuffix].first != nil
        }
    }

    public func stubMatcher<T: XSDType & ExpressibleByXML>(
        requestMatcher: @escaping (T) -> Bool, dataModifier: @escaping (Data) -> Data = { $0 }
    ) -> HTTPStubsTestBlock {
        return { request in
            guard self.stubMatcher(T.self, dataModifier: dataModifier)(request) else {
                return false
            }

            guard let data = (request as NSURLRequest).ohhttpStubs_HTTPBody().map(dataModifier),
                let xml = try? Fuzi.XMLDocument(data: data),
                let soapMessage = SOAPMessage(xml: xml, targetNamespace: self.targetNamespace),
                let req = (T(soapMessage: soapMessage).flatMap { $0 })
            else { return false }
            return requestMatcher(req)
        }
    }

    public func stubBuilder<R: XSDType>(
        _ response: R,
        dataModifier: @escaping (Data) -> Data = { $0 }
    ) -> HTTPStubsResponseBlock {
        let targetNamespace = self.targetNamespace
        let soapResponse = self.soapRequest(response, targetNamespace)
        guard let data = soapResponse.xml.data(using: .utf8) else {
            return { _ in HTTPStubsResponse(error: NSError(domain: "", code: 0, userInfo: nil)) }
        }
        return stubBuilder(dataModifier(data))
    }

    public func stubBuilder(_ response: Data) -> HTTPStubsResponseBlock {
        return { _ in
            return HTTPStubsResponse(
                data: response, statusCode: 200,
                headers: ["Content-Type": "text/xml; charset=utf-8"])
        }
    }
}
