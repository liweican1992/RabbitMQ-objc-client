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

class RMQURIParseTest: XCTestCase {
    
    func testNonAMQPSchemesNotAllowed() {
        XCTAssertThrowsError(try RMQURI.parse("amqpfoo://dev.rabbitmq.com")) { error in
            do {
                XCTAssertEqual(
                    RMQError.InvalidScheme.rawValue,
                    (error as NSError).code
                )
            }
        }
    }
    
    func testHandlesAMQPURIsWithoutPathPart() {
        let val = try! RMQURI.parse("amqp://dev.rabbitmq.com")
        XCTAssertEqual("/", val.vhost)
        XCTAssertEqual("dev.rabbitmq.com", val.host)
        XCTAssertEqual(5672, val.portNumber)
        XCTAssertFalse(val.isTLS)
    }
    
    func testHandlesAMQPSURIsWithoutPathPart() {
        let val = try! RMQURI.parse("amqps://dev.rabbitmq.com")
        XCTAssertEqual("/", val.vhost)
        XCTAssertEqual("dev.rabbitmq.com", val.host)
        XCTAssertEqual(5671, val.portNumber)
        XCTAssertTrue(val.isTLS)
    }
    
    func testParsesVhostAsEmptyStringWhenPathIsJustASlash() {
        let val = try! RMQURI.parse("amqp://dev.rabbitmq.com/")
        XCTAssertEqual("", val.vhost)
    }
    
    func testPercentEncodedSlashIsJustSlash() {
        let val = try! RMQURI.parse("amqp://dev.rabbitmq.com/%2Fvault")
        XCTAssertEqual("/vault", val.vhost)
    }
    
    func testDoesNotIncludeSlashesWhenNoneAfterFirst() {
        let val = try! RMQURI.parse("amqp://dev.rabbitmq.com/a.path.without.slashes")
        XCTAssertEqual("a.path.without.slashes", val.vhost)
    }
    
    func testSlashesNotAllowedInVhost() {
        XCTAssertThrowsError(try RMQURI.parse("amqp://dev.rabbitmq.com/a/path/with/slashes")) { (error) in
            do {
                XCTAssertEqual(
                    RMQError.InvalidPath.rawValue,
                    (error as NSError).code
                )
            }
        }
    }
    
    func testParsesUsernameAndPassword() {
        let val = try! RMQURI.parse("amqp://hedgehog:t0ps3kr3t@hub.megacorp.internal")
        XCTAssertEqual("/", val.vhost)
        XCTAssertEqual("hub.megacorp.internal", val.host)
        XCTAssertEqual(5672, val.portNumber)
        XCTAssertFalse(val.isTLS)
        XCTAssertEqual("hedgehog", val.username)
        XCTAssertEqual("t0ps3kr3t", val.password)
    }

    func testParsesPort() {
        let amqp = try! RMQURI.parse("amqp://foo:bar@bob.cob:443")
        XCTAssertEqual(443, amqp.portNumber)
        let amqps = try! RMQURI.parse("amqps://foo:bar@bob.cob:123")
        XCTAssertEqual(123, amqps.portNumber)
    }

}
