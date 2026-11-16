import XCTest
@testable import LittleBook

/// 12.1：最後一個參數是 completion block 的 ObjC 方法，Swift 端會自動多一個 async 版。
///   ObjC： - (void)fetchRatesForBase:(NSString *)base completion:(LBRatesCompletion)completion;
///   Swift：func fetchRates(forBase: String) async throws -> [String: NSDecimalNumber]
/// block 的 NSError 參數變成 throws；rates 從 nullable 變成非 Optional。
/// 網路一律走 LBStubURLProtocol（測試 bridging header 匯入），不打真的 API。
final class LBSwiftAsyncTests: XCTestCase {

    private let latestPath = "/api/latest"
    private var service: LBRateService!

    override func setUp() {
        super.setUp()
        LBStubURLProtocol.removeAllStubs()
        service = LBRateService(session: LBStubURLProtocol.stubbedSession(),
                                baseURL: URL(string: "https://stub.littlebook.test/api")!)
    }

    override func tearDown() {
        LBStubURLProtocol.removeAllStubs()
        service = nil
        super.tearDown()
    }

    func testFetchRatesCanBeAwaitedFromSwift() async throws {
        let json = #"{"base":"USD","rates":{"TWD":32.15,"JPY":149.5}}"#
        LBStubURLProtocol.stubPath(latestPath, statusCode: 200, data: Data(json.utf8))

        let rates = try await service.fetchRates(forBase: "USD")
        XCTAssertEqual(rates.count, 2)
        XCTAssertEqual(rates["TWD"]?.doubleValue ?? 0, 32.15, accuracy: 0.0001)
    }

    func testFetchRatesErrorBecomesThrow() async {
        LBStubURLProtocol.stubPath(latestPath, statusCode: 500, data: Data())
        do {
            _ = try await service.fetchRates(forBase: "USD")
            XCTFail("HTTP 500 應該丟錯誤")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, LBErrorDomain)
            XCTAssertEqual(nsError.code, 102)   // LBErrorCodeHTTPStatus
        }
    }
}
