//
//  OrientationTest.swift
//  SBFrames
//
//  Created by Ed Gamble on 7/2/16.
//  Copyright © 2016 Edward B. Gamble Jr.  All rights reserved.
//
//  See the LICENSE file at the project root for license information.
//  See the CONTRIBUTORS file at the project root for a list of contributors.
//

import XCTest
import SBUnits
import GLKit

@testable import SBFrames

class OrientationTest: XCTestCase {
  
  let accuracy = Quaternion.epsilon
  let base = Frame.root
  
  let a0   = Quantity<Angle>(value: 0.0, unit: radian)
  let a45  = Quantity<Angle>(value: Double.pi / 4, unit: radian)
  let a90  = Quantity<Angle>(value: Double.pi / 2, unit: radian)
  let a180 = Quantity<Angle>(value: Double.pi / 1, unit: radian)
  
  let a90n  = Quantity<Angle>(value: -Double.pi / 2, unit: radian)

  override func setUp() {
    super.setUp()
    
    // What does Apple say is the direction for a quaternion with 0 angle?
    let g1 = GLKQuaternionMakeWithAngleAndAxis (0, 0, 0, 1)
    let angle = GLKQuaternionAngle (g1)
    let axis  = GLKQuaternionAxis (g1)
    
    XCTAssertEqual(Double( angle), 0.0, accuracy: 1e-5)
    XCTAssertEqual(Double(axis.x), 0.0, accuracy: 1e-5)
    XCTAssertEqual(Double(axis.y), 0.0, accuracy: 1e-5)
    XCTAssertEqual(Double(axis.z), 0.0, accuracy: 1e-3)
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func checkValues (_ p: Position, frame: Frame, unit: SBUnits.Unit<Length>, x: Double, y: Double, z: Double) {
    XCTAssert(p.has (frame: frame))
    XCTAssertEqual(p.x.value, x, accuracy: accuracy)
    XCTAssertEqual(p.y.value, y, accuracy: accuracy)
    XCTAssertEqual(p.z.value, z, accuracy: accuracy)
    
    XCTAssertTrue(p.x.unit === unit)
    XCTAssertTrue(p.y.unit === unit)
    XCTAssertTrue(p.z.unit === unit)
    
    XCTAssertTrue(p.unit === unit)
    XCTAssertEqual(p.unit, unit)
  }

  func checkOrientation (_ o: Orientation, frame: Frame, a: Double, x: Double, y: Double, z: Double) {    
    guard let (ao, (xo, yo, zo)) = o.quat.asAngleDirection else {
      XCTAssert(false)
      return
    }

    XCTAssertEqual(ao, a, accuracy: accuracy)
    XCTAssertEqual(xo, x, accuracy: accuracy)
    XCTAssertEqual(yo, y, accuracy: accuracy)
    XCTAssertEqual(zo, z, accuracy: accuracy)
    
    XCTAssert(o.has (frame: frame))
  }

  func checkQuant (qA: Quaternion, qB: Quaternion) {
    XCTAssertEqual(qA.q0, qB.q0, accuracy: accuracy)
    XCTAssertEqual(qA.q1, qB.q1, accuracy: accuracy)
    XCTAssertEqual(qA.q2, qB.q2, accuracy: accuracy)
    XCTAssertEqual(qA.q3, qB.q3, accuracy: accuracy)
  }
  
  func testInit() {
    let ob  = Orientation (frame: base)
    
    let o0  = Orientation (frame: base, angle:  a0, axis: .z)
    checkOrientation(o0, frame: base, a: a0.value, x: 0, y: 0, z: 0)

    let o45 = Orientation (frame: base, angle: a45, axis: .z)

    let o90 = Orientation (frame: base, angle: a90, axis: .z)
    checkOrientation(o90, frame: base, a: a90.value, x: 0, y: 0, z: 1)

    let _ = [ob, o0, o45,o90]
  }
  
  func testInvert () {
    // rot .z 90
    let o90p  = Orientation (frame: base, angle:  a90 , axis: .z)
    checkOrientation(o90p, frame: base, a: a90.value, x: 0, y: 0, z: 1)

    // rot .z -90 -> quat ambiguity rot -.z 90
    let o90n  = Orientation (frame: base, angle:  a90n, axis: .z)
    checkOrientation(o90n, frame: base, a: a90.value, x: 0, y: 0, z: -1)

    // rot .z 90 .invert ->
    let o90i = o90p.inverse
    checkOrientation(o90i, frame: base, a: a90.value, x: 0, y: 0, z: -1)
    
    let oc = o90p.compose(o90i)
    checkOrientation(oc, frame: base, a: 0, x: 0, y: 0, z: 0)
  }
  
  func testCompose () {
    let o0  = Orientation (frame: base, angle:  a0, axis: .z)
    checkOrientation(o0, frame: base, a: a0.value, x: 0, y: 0, z: 0)
    let o45 = Orientation (frame: base, angle: a45, axis: .z)
    let o90 = Orientation (frame: base, angle: a90, axis: .z)
    checkOrientation(o90, frame: base, a: a90.value, x: 0, y: 0, z: 1)

    let o90c = o0.compose(o45).compose(o45)
    checkOrientation(o90c, frame: base, a: a90.value, x: 0, y: 0, z: 1)
    
    let o0c = o90c.compose(o90.inverse)
    checkOrientation(o0c, frame: base, a: a0.value, x: 0, y: 0, z: 1)
  }
  
  func testRotate () {
    let o45 = Orientation (frame: base, angle: a45, axis: .z)
  
    let c90 = o45.compose(o45)
    let o90 = Orientation (frame: base, angle: a90, axis: .z)
    
    XCTAssertEqual(c90.quat.q0, o90.quat.q0, accuracy: 1e-10)
  
    let c180 = o90.compose(o90)
    let o180 = Orientation (frame: base, angle: a180, axis: .z)
    XCTAssertEqual(c180.quat.q0, o180.quat.q0, accuracy: 1e-10)
    
    
    let o180x = Orientation (frame: base, angle: a180, axis: .z)
    let c180x = Orientation (frame: base, angle: a0, axis: .z).compose(o180x)
    checkQuant(qA: o180x.quat, qB: c180x.quat)
  }

  /*
  func testAngles () {
    let (phi,theta,psi) = (37.5, 10.0, 22.0)
    let o1 = Orientation(frame: base, unit: degree, convention: .fixedXYZ, x: phi, y: theta, z: psi)
    let (oPhi, oTheta, oPsi) = o1.asFixedXYZAngles


    XCTAssertEqual(phi, degree.convert(oPhi, unit: radian), accuracy: 1e-10)
    XCTAssertEqual(theta, degree.convert(oTheta, unit: radian), accuracy: 1e-10)
    XCTAssertEqual(psi, degree.convert(oPsi, unit: radian), accuracy: 1e-10)

  }
*/
  func testPerformanceExample() {
    self.measure {
    }
  }
}
