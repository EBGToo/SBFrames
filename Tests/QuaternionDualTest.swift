//
//  QuaternionDualTest.swift
//  SBFrames
//
//  Created by Ed Gamble on 7/13/16.
//  Copyright © 2016 Edward B. Gamble Jr.  All rights reserved.
//
//  See the LICENSE file at the project root for license information.
//  See the CONTRIBUTORS file at the project root for a list of contributors.
//

import XCTest
import SBUnits
import GLKit

@testable import SBFrames

class QuaternionDualTest: XCTestCase {
  
  let accuracy = Quaternion.epsilon
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func checkValues (_ q: Quaternion, q0: Double, q1: Double, q2: Double, q3: Double) {
    XCTAssertEqual(q.q0, q0, accuracy: accuracy)
    XCTAssertEqual(q.q1, q1, accuracy: accuracy)
    XCTAssertEqual(q.q2, q2, accuracy: accuracy)
    XCTAssertEqual(q.q3, q3, accuracy: accuracy)
  }
  
  func testInit() {
    let da = DualQuaternion.identity
    XCTAssertEqual (da.real, Quaternion.identity)
    XCTAssertEqual (da.dual, Quaternion.zero)
    
    let dqr = Quaternion.identity
    let dqd = Quaternion.zero
    
    let db = DualQuaternion(real: dqr, dual: dqd)
    XCTAssertEqual (db.real, Quaternion.identity)
    XCTAssertEqual (db.dual, Quaternion.zero)
    
    let dqt = Quaternion (q0: 0.0, q1: 1.0, q2: 0.0, q3: 0.0)
    let dc = DualQuaternion (translation: dqt)
    let dct = dc.asTranslation
    XCTAssertEqual(dct, dqt)
    
    // Check 'unit Condition' (qr* * qd + qd* * qr) = 0
    let dqrr = Quaternion.makeAsAngleDirection(angle: Double.pi/2, direction: (0.0, 0.0, 1.0))!
    let dd = DualQuaternion (rotation: dqrr, translation: dqt)
    let duc = dd.unitCondition
    checkValues(duc, q0: 0.0, q1: 0.0, q2: 0.0, q3: 0.0)
  }

  func testNorm () {
    
  }
  
  func testConjugate () {
    let qr = Quaternion (q0: 0.0, q1: 1.0, q2: 2.0, q3: 3.0)
    let qd = Quaternion (q0: 3.0, q1: 2.0, q2: 1.0, q3: 0.0)
    
    let d = DualQuaternion (real: qr, dual: qd)
    let dc = d.conjugate(.QUATERNION)
    
    XCTAssertEqual(dc.real, qr.conjugate)
    XCTAssertEqual(dc.dual, qd.conjugate)
  }

  func testOffset () {
    let da = DualQuaternion(real: Quaternion.zero,
                            dual: Quaternion.zero)
    let ta = Quaternion (q0: 0.0, q1: 1.0, q2: 0.0, q3: 0.0)
    
    let d0 = da + DualQuaternion(real: Quaternion.identity,
                                 dual:  ta)
    XCTAssertEqual(d0.real, Quaternion.identity)
    XCTAssertEqual(d0.dual, ta)
    
    let d1 = d0 + d0
    XCTAssertEqual(d1.real, 2.0 * Quaternion.identity)
    XCTAssertEqual(d1.dual, 2.0 * ta)
  }
  
  func testCompose () {
    
    // Compose two transalations
    let qt = Quaternion (q0: 0.0, q1: 1.0, q2: 0.0, q3: 0.0)
    let dt = DualQuaternion (translation: qt)
    
    let d0 = dt * dt
    
    let (rotation:q0r, translation:q0t) = d0.asRotationAndTranslation
    
    checkValues(q0t, q0: 0.0, q1: 2.0, q2: 0.0, q3: 0.0)
    checkValues(q0r, q0: 1.0, q1: 0.0, q2: 0.0, q3: 0.0)

    // Compose two rotations
    let qr = Quaternion.makeAsAngleDirection(angle: Double.pi/2, direction: (0.0, 0.0, 1.0))!
    let dr = DualQuaternion (rotation: qr)
    
    let d1 = dr * dr
    let (rotation:q1r, translation:q1t) = d1.asRotationAndTranslation
    let (angle:ad1, direction:dd1) = q1r.asAngleDirection!
    
    checkValues(q1t, q0: 0.0, q1: 0.0, q2: 0.0, q3: 0.0)
    XCTAssertEqual(ad1, Double.pi, accuracy: accuracy)
    XCTAssertEqual(dd1.0, 0.0, accuracy: accuracy)
    XCTAssertEqual(dd1.1, 0.0, accuracy: accuracy)
    XCTAssertEqual(dd1.2, 1.0, accuracy: accuracy)

    // Compose translation then rotation
    let d2 = dr * dt
    let (rotation:q2r, translation:q2t) = d2.asRotationAndTranslation

    // FAIL
    checkValues(q2t, q0: 0.0, q1: 0.0, q2: 1.0, q3: 0.0)
    XCTAssertEqual(q2r, Quaternion.makeAsAngleDirection(angle: Double.pi/2, direction: (0.0, 0.0, 1.0))!)
    //    XCTAssert (false, "Unexpected success")
    
    let p = Quaternion (q0: 0.0, q1: 0.0, q2: 2.0, q3: 0.0)
    let px = d2.transform(translation: p)
    checkValues(px, q0: 0.0, q1: -2.0, q2: 1.0, q3: 0.0)
    //    XCTAssertEqual(q0t, qt.rotate(by: qr))
    //
  }
  
  func testComposeJiaB0 () {
    let q0 = Quaternion (q0: 0.0, q1: 1.0, q2: 0.0, q3: 0.0)
    let q1 = Quaternion (q0: 0.0, q1: 0.0, q2: 0.0, q3: 2.0)
    
    let q01 = q0 + q1
    XCTAssertEqual(q01, Quaternion(q0: 0.0, q1: 1.0, q2: 0.0, q3: 2.0))
    
    XCTAssertEqual(DualQuaternion (translation: q01).asTranslation,
                   Quaternion (q0: 0.0, q1: 1.0, q2: 0.0, q3: 2.0))
    
    
    let d0 = DualQuaternion (translation: q0)
    let d1 = DualQuaternion (translation: q1)
    let d01 = d1 * d0

    XCTAssertEqual(d01.asRotation,    Quaternion.identity)
    XCTAssertEqual(d01.asTranslation, Quaternion (q0: 0.0, q1: 1.0, q2: 0.0, q3: 2.0))
  }
  
  //
  // dt * dr is identical to [dr,dt]
  //
  func testComposeJiaB () {
    let dr = DualQuaternion (rotation: Quaternion.makeAsAngleDirection(angle: 2*Double.pi/3, direction: (1.0, 1.0, 1.0))!)
    let dt = DualQuaternion (translation: Quaternion (q0: 0.0, q1: 0.0, q2: 0.0, q3: 3.0))
    
    let drt0 = dt * dr
    let drt1 = DualQuaternion (rotation: Quaternion.makeAsAngleDirection(angle: 2*Double.pi/3, direction: (1.0, 1.0, 1.0))!,
                               translation: Quaternion (q0: 0.0, q1: 0.0, q2: 0.0, q3: 3.0))
    XCTAssertEqual(drt0.real, drt1.real)
    XCTAssertEqual(drt0.dual, drt1.dual)
    XCTAssertEqual(drt0, drt1)

  }
  func testComposeJiaR () {
    let drt = DualQuaternion (rotation: Quaternion.makeAsAngleDirection(angle: 2*Double.pi/3, direction: (1.0, 1.0, 1.0))!)
    checkValues(drt.real, q0: 0.5, q1: 0.5, q2: 0.5, q3: 0.5)
    
    let p = Quaternion (q0: 0.0, q1: 2.0, q2: 0.0, q3: 0.0)
    let px = drt.transform (translation: p)
    XCTAssertEqual(px.q0, 0.0, accuracy: accuracy)
    XCTAssertEqual(px.q1, 0.0, accuracy: accuracy)
    XCTAssertEqual(px.q2, 2.0, accuracy: accuracy)
    XCTAssertEqual(px.q3, 0.0, accuracy: accuracy)
  }
  
  func testComposeJiaT () {
    let drt = DualQuaternion (translation: Quaternion (q0: 0.0, q1: 0.0, q2: 0.0, q3: 3.0))
    checkValues(drt.asTranslation, q0: 0.0, q1: 0.0, q2: 0.0, q3: 3.0)
    checkValues(drt.dual, q0: 0.0, q1: 0.0, q2: 0.0, q3: 1.5)
    checkValues(drt.real, q0: 1.0, q1: 0.0, q2: 0.0, q3: 0.0)
    
    let p = Quaternion (q0: 0.0, q1: 2.0, q2: 0.0, q3: 0.0)
    let px = drt.transform(translation: p)
    XCTAssertEqual(px.q0, 0.0, accuracy: accuracy)
    XCTAssertEqual(px.q1, 2.0, accuracy: accuracy)
    XCTAssertEqual(px.q2, 0.0, accuracy: accuracy)
    XCTAssertEqual(px.q3, 3.0, accuracy: accuracy)
  }
  
  func testComposeJia () {
    let drt = DualQuaternion (rotation: Quaternion.makeAsAngleDirection(angle: 2*Double.pi/3, direction: (1.0, 1.0, 1.0))!,
                              translation: Quaternion (q0: 0.0, q1: 0.0, q2: 0.0, q3: 3.0))
    checkValues(drt.asRotation,    q0: 0.5, q1: 0.5, q2: 0.5, q3: 0.5)
    checkValues(drt.asTranslation, q0: 0.0, q1: 0.0, q2: 0.0, q3: 3.0)
    
    let p = Quaternion (q0: 0.0, q1: 2.0, q2: 0.0, q3: 0.0)
    let px = drt.transform(translation: p)
    XCTAssertEqual(px.q0, 0.0, accuracy: accuracy)
    XCTAssertEqual(px.q1, 0.0, accuracy: accuracy)
    XCTAssertEqual(px.q2, 2.0, accuracy: accuracy)
    XCTAssertEqual(px.q3, 3.0, accuracy: accuracy)
  }
  
  func testInverse () {
    let drt = DualQuaternion (rotation: Quaternion.makeAsAngleDirection(angle: 2*Double.pi/3, direction: (1.0, 1.0, 1.0))!,
                              translation: Quaternion (q0: 0.0, q1: 0.0, q2: 0.0, q3: 3.0))
    checkValues(drt.asRotation,    q0: 0.5, q1: 0.5, q2: 0.5, q3: 0.5)
    checkValues(drt.asTranslation, q0: 0.0, q1: 0.0, q2: 0.0, q3: 3.0)

    let drto = drt * drt.inverse
    checkValues(drto.asRotation,    q0: 1.0, q1: 0.0, q2: 0.0, q3: 0.0)
    checkValues(drto.asTranslation, q0: 0.0, q1: 0.0, q2: 0.0, q3: 0.0)

    let drti = drt.inverse
    checkValues(drti.asTranslation, q0: 0.0, q1: 0.0, q2: -3.0, q3: 0.0)
    checkValues(drti.asRotation, q0: 0.5, q1: -0.5, q2: -0.5, q3: -0.5)
  }
  
  
  func testPredicate () {
    
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
}

