// This source code is dual-licensed under the Mozilla Public License ("MPL"),
// version 1.1 and the Apache License ("ASL"), version 2.0.
//
// The ASL v2.0:
//
// ---------------------------------------------------------------------------
// Copyright 2016 Pivotal Software, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ---------------------------------------------------------------------------
//
// The MPL v1.1:
//
// ---------------------------------------------------------------------------
// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// https://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//
// The Original Code is RabbitMQ
//
// The Initial Developer of the Original Code is Pivotal Software, Inc.
// All Rights Reserved.
//
// Alternatively, the contents of this file may be used under the terms
// of the Apache Standard license (the "ASL License"), in which case the
// provisions of the ASL License are applicable instead of those
// above. If you wish to allow use of your version of this file only
// under the terms of the ASL License and not to allow others to use
// your version of this file under the MPL, indicate your decision by
// deleting the provisions above and replace them with the notice and
// other provisions required by the ASL License. If you do not delete
// the provisions above, a recipient may use your version of this file
// under either the MPL or the ASL License.
// ---------------------------------------------------------------------------

import XCTest

class RMQParserTest: XCTestCase {

    func testOctet() {
        let parser = RMQParser(data: "\u{2}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual(2, parser.parseOctet())

        for _ in 1...1000 {
            XCTAssertEqual(0, parser.parseOctet())
        }
    }

    func testBoolean() {
        let parser = RMQParser(data: "\u{1}\u{0}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertTrue(parser.parseBoolean())
        XCTAssertFalse(parser.parseBoolean())

        for _ in 1...1000 {
            XCTAssertFalse(parser.parseBoolean())
        }
    }

    func testShortString() {
        let s = "PRECONDITION_FAILED - inequivalent arg 'durable' for queue 'rmqclient.integration-tests.E0B5A093-6B2E-402C-84F3-E93B59DF807B-71865-0003F85C24C90FC6' in vhost '/': received 'false' but current is 'true'"
        let data = NSMutableData()
        var stringLength = s.characters.count
        data.appendBytes(&stringLength, length: 1)
        data.appendData(s.dataUsingEncoding(NSUTF8StringEncoding)!)
        data.appendData("stuffthatshouldn'tbeparsed".dataUsingEncoding(NSUTF8StringEncoding)!)

        let parser = RMQParser(data: data)
        XCTAssertEqual(s, parser.parseShortString())
    }

    func testShortStringWhenAlreadyRead() {
        let parser = RMQParser(data: "\u{4}aaaa".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual("aaaa", parser.parseShortString())
        for _ in 1...1000 {
            XCTAssertEqual("", parser.parseShortString())
        }
    }

    func testShortStringWhenNotEnoughDataToReadAfterLongString() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{0}\u{4}AAAA\u{4}BBB".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual("AAAA", parser.parseLongString())
        XCTAssertEqual("", parser.parseShortString())
    }

    func testLongString() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{0}\u{4}AAAAbbbb".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual("AAAA", parser.parseLongString())
    }

    func testLongStringWhenAlreadyRead() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{0}\u{4}AAAA".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual("AAAA", parser.parseLongString())
        for _ in 1...1000 {
            XCTAssertEqual("", parser.parseLongString())
        }
    }

    func testLongStringWhenNotEnoughDataToRead() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{0}\u{4}AAA".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual("", parser.parseLongString())
    }

    func testLongStringWhenNotEnoughDataToReadAfterShortString() {
        let parser = RMQParser(data: "\u{4}BBBB\u{0}\u{0}\u{0}\u{4}AAA".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual("BBBB", parser.parseShortString())
        XCTAssertEqual("", parser.parseLongString())
    }

    func testLongUInt() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{0}\u{10}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual(16, parser.parseLongUInt())
    }

    func testLongUIntWhenAlreadyRead() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{1}\u{0}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual(256, parser.parseLongUInt())
        for _ in 1...1000 {
            XCTAssertEqual(0, parser.parseLongUInt())
        }
    }

    func testLongUIntWhenNotEnoughDataToRead() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{1}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual(0, parser.parseLongUInt())
    }

    func testLongLongUInt() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{0}\u{0}\u{0}\u{0}\u{0}\u{10}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual(16, parser.parseLongLongUInt())
    }

    func testLongLongUIntWhenAlreadyRead() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{0}\u{0}\u{0}\u{0}\u{1}\u{0}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual(256, parser.parseLongLongUInt())
        for _ in 1...1000 {
            XCTAssertEqual(0, parser.parseLongLongUInt())
        }
    }

    func testLongLongUIntWhenNotEnoughDataToRead() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{0}\u{0}\u{0}\u{0}\u{1}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual(0, parser.parseLongLongUInt())
    }

    func testShortUInt() {
        let parser = RMQParser(data: "\u{0}\u{10}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual(16, parser.parseShortUInt())
    }

    func testShortUIntWhenAlreadyRead() {
        let parser = RMQParser(data: "\u{1}\u{0}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual(256, parser.parseShortUInt())
        for _ in 1...1000 {
            XCTAssertEqual(0, parser.parseShortUInt())
        }
    }

    func testShortUIntWhenNotEnoughDataToRead() {
        let parser = RMQParser(data: "\u{1}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual(0, parser.parseShortUInt())
    }
    
    func testFieldTableWithAllTypes() {
        let signedByte: Int8 = -128
        let date = NSDate.distantFuture()
        var dict: [String: RMQValue] = [:]
        dict["boolean"]         = RMQBoolean(true)
        dict["signed-8-bit"]    = RMQSignedByte(signedByte)
        dict["signed-16-bit"]   = RMQSignedShort(-129)
        dict["unsigned-16-bit"] = RMQShort(65535)
        dict["signed-32-bit"]   = RMQSignedLong(-2147483648)
        dict["unsigned-32-bit"] = RMQLong(4294967295)
        dict["signed-64-bit"]   = RMQSignedLonglong(-9223372036854775808)
        dict["32-bit-float"]    = RMQFloat(123.5123)
        dict["64-bit-float"]    = RMQDouble(9000000.5)
        dict["decimal"]         = RMQDecimal()
        dict["long-string"]     = RMQLongstr("foo")
        dict["array"]           = RMQArray([RMQLongstr("hi"), RMQBoolean(false)])
        dict["timestamp"]       = RMQTimestamp(date)
        dict["nested-table"]    = RMQTable(["foo": RMQLong(23)])
        dict["void"]            = RMQVoid()
        dict["byte-array"]      = RMQByteArray("hi".dataUsingEncoding(NSUTF8StringEncoding)!)

        let table = RMQTable(dict)
        let parser = RMQParser(data: table.amqEncoded())
        XCTAssertEqual(dict, parser.parseFieldTable())
    }

    func testGetEmptyDictWhenFieldTableIncludesValueWithBadSize() {
        var dict: [String: RMQValue] = [:]
        dict["unsigned-16-bit"]      = RMQShort(65535)
        dict["bad-size"]             = ValueWithBadSize(123)

        let table = RMQTable(dict)
        let data = table.amqEncoded()
        let parser = RMQParser(data: data)
        XCTAssertEqual([:], parser.parseFieldTable())
    }

    @objc class ValueWithBadSize : RMQSignedLong {
        override func amqEncoded() -> NSData {
            var longVal = CFSwapInt32HostToBig(UInt32(self.integerValue))
            return NSData(bytes: &longVal, length: 1)
        }
    }
}
