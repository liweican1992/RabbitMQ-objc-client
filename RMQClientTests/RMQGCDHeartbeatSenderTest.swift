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

class RMQGCDHeartbeatSenderTest: XCTestCase {
    func makeSender() -> (sender: RMQGCDHeartbeatSender, transport: ControlledInteractionTransport, clock: FakeClock) {
        let transport = ControlledInteractionTransport()
        let clock = FakeClock()
        let sender = RMQGCDHeartbeatSender(transport: transport,
                                           clock: clock)

        return (sender, transport, clock)
    }

    func testSendsHeartbeatsRegularly() {
        let (sender, transport, clock) = makeSender()
        let beat = RMQHeartbeat().amqEncoded()

        let handler = sender.startWithInterval(1)
        sender.stop() // don't let scheduled runs interfere with test runs

        clock.advance(1.01)
        handler()
        clock.advance(1)
        handler()

        XCTAssertEqual([beat, beat], transport.outboundData)
    }

    func testDoesNotBeatIfIntervalNotPassed() {
        let (sender, transport, clock) = makeSender()

        let handler = sender.startWithInterval(1)
        sender.stop()

        clock.advance(1)
        handler()

        XCTAssertEqual([], transport.outboundData)
    }

    func testDoesNotBeatIfActivityRecentlySignalled() {
        let (sender, transport, clock) = makeSender()

        let handler = sender.startWithInterval(1)
        sender.stop()

        clock.advance(1.01)
        sender.signalActivity()
        handler()

        XCTAssertEqual([], transport.outboundData)
    }

    func testCanBeStoppedAndStartedWithoutOverResumeException() {
        let (sender, _, _) = makeSender()

        sender.startWithInterval(0.01)
        sender.stop()
        sender.startWithInterval(0.01)
    }

    func testCanBeStoppedBeforeBeingStartedWithoutBadAccess() {
        let (sender, _, _) = makeSender()

        sender.stop()
    }
}
