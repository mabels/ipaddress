import XCTest
@testable import IpAddressTests

XCTMain([
	testCase(IPAddressTests.allTests),
	testCase(Ipv4Tests.allTests),
	testCase(Ipv6LoopbackTests.allTests),
	testCase(Ipv6MappedTests.allTests),
	testCase(Ipv6Tests.allTests),
	testCase(Ipv6UnspecTests.allTests),
	testCase(Prefix128Tests.allTests),
	testCase(Prefix32Tests.allTests),
	testCase(RleTests.allTests)
])
