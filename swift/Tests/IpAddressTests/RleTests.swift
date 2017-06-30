import XCTest
//@testable import swift


@testable import IpAddress

//typealias Rle<Int> = Rle<Int>

class RleTests: XCTestCase {
  func testRle() {
        let empty = [Int]();
        XCTAssertEqual(Rle<Int>.code(empty), [Rle<Int>]());
        XCTAssertEqual(Rle<Int>.code([4711]), [
                Rle<Int>(
                        part: 4711,
                        pos: 0,
                        cnt: 1,
                        max: true
                    )]);
        XCTAssertEqual(Rle<Int>.code([4711, 4711]), [
                Rle<Int>(
                        part: 4711,
                        pos: 0,
                        cnt: 2,
                        max: true
                    )]);
        XCTAssertEqual(Rle<Int>.code([4711, 4711, 4811]), [
                    Rle<Int>(
                        part: 4711,
                        pos: 0,
                        cnt: 2,
                        max: true
                    ),
                    Rle<Int>(
                        part: 4811,
                        pos: 1,
                        cnt: 1,
                        max: true
                    )]);
        XCTAssertEqual(Rle<Int>.code([4711, 4711, 4811, 4711, 4711]), [
                    Rle<Int>(
                        part: 4711,
                        pos: 0,
                        cnt: 2,
                        max: true
                    ),
                    Rle<Int>(
                        part: 4811,
                        pos: 1,
                        cnt: 1,
                        max: true
                    ),
                    Rle<Int>(
                        part: 4711,
                        pos: 2,
                        cnt: 2,
                        max: true
                    )]);
              XCTAssertEqual(Rle<Int>.code([4711, 4711, 4711, 4811, 4711, 4711]), [
                    Rle<Int>(
                        part: 4711,
                        pos: 0,
                        cnt: 3,
                        max: true
                    ),
                    Rle<Int>(
                        part: 4811,
                        pos: 1,
                        cnt: 1,
                        max: true
                    ),
                    Rle<Int>(
                        part: 4711,
                        pos: 2,
                        cnt: 2,
                        max: false
                    )]
                   );
                   XCTAssertEqual(Rle<Int>.code([4711, 4711, 4711, 4811, 4711, 4711, 4911, 4911, 4911]), 
                       [
                        Rle<Int>(
                           part: 4711,
                           pos: 0,
                           cnt: 3,
                           max: true
                       ),
                       Rle<Int>(
                           part: 4811,
                           pos: 1,
                           cnt: 1,
                           max: true
                       ),
                       Rle<Int>(
                           part: 4711,
                           pos: 2,
                           cnt: 2,
                           max: false
                       ),
                       Rle<Int>(
                           part: 4911,
                           pos: 3,
                           cnt: 3,
                           max: true
                       )]);


              XCTAssertEqual(Rle<Int>.code([0x2001, 0x888, 0, 0x6630, 0, 0, 0, 0]), [
                   Rle<Int>(
                       part: 0x2001,
                       pos: 0,
                       cnt: 1,
                       max: true
                   ),
                   Rle<Int>(
                       part: 0x888,
                       pos: 1,
                       cnt: 1,
                       max: true
                   ),
                   Rle<Int>(
                       part: 0,
                       pos: 2,
                       cnt: 1,
                       max: false
                   ),
                   Rle<Int>(
                       part: 0x6630,
                       pos: 3,
                       cnt: 1,
                       max: true
                   ),
                   Rle<Int>(
                       part: 0,
                       pos: 4,
                       cnt: 4,
                       max: true
                   )
       ]);
    }
}
