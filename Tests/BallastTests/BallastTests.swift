import XCTest
@testable import Ballast

class TestClass {
    var data: String
    var identity: UUID = UUID()
    init(data: String) {
        self.data = data
    }
}

extension Notification.Name {
    static let Jetsam = Notification.Name(rawValue: "com.fcanas.Jetsam")
}

final class UnretainedBallastTests: XCTestCase {
    @Ballast(TestClass(data: "thing1"))
    var unretained: TestClass
    
    func testStableDataAndIdentityWhenRetained() {
        let thing1Retained: TestClass = unretained
        XCTAssertEqual(thing1Retained.data, "thing1")
        XCTAssertEqual(thing1Retained.identity, unretained.identity)
    }
    
    func testStableDataAndUnstableIdentityWhenReleased() throws {
        var thing1Retained: TestClass? = unretained
        XCTAssertEqual(try XCTUnwrap(thing1Retained).data, "thing1")
        XCTAssertEqual(try XCTUnwrap(thing1Retained).identity, unretained.identity)
        let identity1 = thing1Retained?.identity
        thing1Retained = nil
        XCTAssertNotEqual(identity1, unretained.identity)
    }
    
    func testUnretainedReleasesImmediately() throws {
        var uuid: UUID! = nil
        weak var localWeakManualRelease: TestClass? = {
            let u = unretained
            uuid = u.identity
            return u
        }()
        XCTAssertNotEqual(uuid, unretained.identity, "Ballast object stored in weak container is released (doesn't maintain identity)")
        XCTAssertNil(localWeakManualRelease, "Local weak variable is released")
    }
}

final class ManualReleaseBallastTests: XCTestCase {
    
    @Ballast(TestClass(data: "manualRelease"), policy: .manualRelease)
    var manualRelease: TestClass
    
    func testManualReleasePolicyRetention() throws {
        weak var localWeakManualRelease = manualRelease
        XCTAssertEqual(try XCTUnwrap(localWeakManualRelease).identity, manualRelease.identity, "Ballast object stored in weak container isn't released (retains identity)")
    }
    
    func testManualReleaseJettison() throws {
        weak var localWeakManualRelease = manualRelease
        XCTAssertNotNil(localWeakManualRelease, "Weak referece to first ballast should be non-null")
        _manualRelease.jettison()
        XCTAssertNil(localWeakManualRelease)
        XCTAssertNotNil(manualRelease)
    }
    
}

final class NotificationReleaseBallastTests: XCTestCase {

    @Ballast(TestClass(data: "notification"), policy: .notification(.Jetsam))
    var notification: TestClass
    
    func testNotificationJettison() throws {
        weak var localWeakManualRelease = notification
        XCTAssertNotNil(localWeakManualRelease, "Weak referece to first ballast should be non-null")
        NotificationCenter.default.post(name: .Jetsam, object: nil)
        XCTAssertNil(localWeakManualRelease)
        XCTAssertNotNil(notification)
    }
    
    // Tests for Manual Release also apply
    
    func testManualReleasePolicyRetention() throws {
        weak var localWeakManualRelease = notification
        XCTAssertEqual(try XCTUnwrap(localWeakManualRelease).identity, notification.identity, "Ballast object stored in weak container isn't released (retains identity)")
    }
    
    func testNotificationReleaseJettison() throws {
        weak var localWeakManualRelease = notification
        XCTAssertNotNil(localWeakManualRelease, "Weak referece to first ballast should be non-null")
        _notification.jettison()
        XCTAssertNil(localWeakManualRelease)
        XCTAssertNotNil(notification)
    }

}

final class DisuseTimeReleaseBallastTests: XCTestCase {

    @Ballast(TestClass(data: "disuse"), policy: .disuse(.milliseconds(50), .main))
    var disuse: TestClass
    
    func testTimedReleasePolicyCrossedThreshold() throws {
        weak var localWeakManualRelease = disuse
        XCTAssertNotNil(localWeakManualRelease, "Weak referece to first ballast should be non-null")
        
        RunLoop.current.run(until: Date().addingTimeInterval(DispatchTimeInterval.milliseconds(55).timeInterval()!))
        
        XCTAssertNotNil(disuse)
        XCTAssertNil(localWeakManualRelease)
    }
    
    func testTimedReleasePolicyRetentionSubThreshold() throws {
        weak var localWeakManualRelease = disuse
        XCTAssertNotNil(localWeakManualRelease, "Weak referece to first ballast should be non-null")
        
        RunLoop.current.run(until: Date().addingTimeInterval(DispatchTimeInterval.milliseconds(5).timeInterval()!))
        
        XCTAssertNotNil(disuse)
        XCTAssertNotNil(localWeakManualRelease)
    }
    
    func testTimedReleasePolicyRetentionRefreshed() throws {
        weak var localWeakManualRelease = disuse
        XCTAssertNotNil(localWeakManualRelease, "Weak referece to first ballast should be non-null")
        
        RunLoop.current.run(until: Date().addingTimeInterval(DispatchTimeInterval.milliseconds(20).timeInterval()!))
        weak var secondLocalWeakManualRelease = disuse
        RunLoop.current.run(until: Date().addingTimeInterval(DispatchTimeInterval.milliseconds(20).timeInterval()!))
        secondLocalWeakManualRelease = disuse
        RunLoop.current.run(until: Date().addingTimeInterval(DispatchTimeInterval.milliseconds(20).timeInterval()!))
        
        XCTAssertNotNil(disuse)
        XCTAssertNotNil(localWeakManualRelease)
        XCTAssertNotNil(secondLocalWeakManualRelease)
    }
    
    // Tests for Manual Release also apply
    
    func testManualReleasePolicyRetention() throws {
        weak var localWeakManualRelease = disuse
        XCTAssertEqual(try XCTUnwrap(localWeakManualRelease).identity, disuse.identity, "Ballast object stored in weak container isn't released (retains identity)")
    }
    
    func testManualReleaseJettison() throws {
        weak var localWeakManualRelease = disuse
        XCTAssertNotNil(localWeakManualRelease, "Weak referece to first ballast should be non-null")
        _disuse.jettison()
        XCTAssertNil(localWeakManualRelease)
        XCTAssertNotNil(disuse)
    }

}
