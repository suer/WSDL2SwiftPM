import Testing

@Test func tempConvert_CelsiusToFahrenheit() async throws {
    let service = TempConvert(endpoint: "http://www.w3schools.com")
    let future = service.request(TempConvert_CelsiusToFahrenheit(Celsius: "23.4"))
    let r = try await future.get()

    #expect(r.CelsiusToFahrenheitResult == "74.12")
}
