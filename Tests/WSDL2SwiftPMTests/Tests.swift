import Testing

@Test func tempConvert_CelsiusToFahrenheit() async throws {
    let service = TempConvert(endpoint: "https://www.w3schools.com")
    let r = try await service.request(TempConvert_CelsiusToFahrenheit(Celsius: "23.4"))

    #expect(r.CelsiusToFahrenheitResult == "74.12")
}
