//
//  DirectionTest.swift
//  SBFrames
//
//  Created by Ed Gamble on 7/5/16.
//  Copyright © 2016 Edward B. Gamble Jr.  All rights reserved.
//
//  See the LICENSE file at the project root for license information.
//  See the CONTRIBUTORS file at the project root for a list of contributors.
//

import XCTest
import SBUnits

@testable import SBFrames

class DirectionTest: XCTestCase {
  
  let accuracy = Quaternion.epsilon
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func checkValues (_ d: Direction, frame: Frame, x: Double, y: Double, z: Double) {
    XCTAssert(d.has (frame: frame))
    XCTAssertEqual(d.x, x, accuracy: accuracy)
    XCTAssertEqual(d.y, y, accuracy: accuracy)
    XCTAssertEqual(d.z, z, accuracy: accuracy)
  }
  
  func checkAngles (_ d: Direction, x: Double, y: Double, z: Double) {
    XCTAssertEqual(d.includedAngle(axis: .x).value, x, accuracy: accuracy)
    XCTAssertEqual(d.includedAngle(axis: .y).value, y, accuracy: accuracy)
    XCTAssertEqual(d.includedAngle(axis: .z).value, z, accuracy: accuracy)
  }
  
  func testInit() {
    let f1 = Frame.root
    
    let p0 = Direction (frame: f1, x: 0.0, y: 0.0, z: 0.0)
    XCTAssertNil(p0)
    
    let p1 = Direction (frame:f1)
    XCTAssertNotNil (p1)

    let px = Direction (frame: f1, x: 1.0, y: 0.0, z: 0.0)
    XCTAssertNotNil(px)
    checkValues (px!, frame: f1, x: 1.0, y: 0.0, z: 0.0)
    checkAngles (px!, x: 0.0, y: Double.pi/2, z: Double.pi/2)
    
    let py = Direction (frame: f1, x: 0.0, y: 1.0, z: 0.0)
    XCTAssertNotNil(py)
    checkValues (py!, frame: f1, x: 0.0, y: 1.0, z: 0.0)
    checkAngles (py!, x: Double.pi/2, y: 0.0, z: Double.pi/2)
    
    let pz = Direction (frame: f1, x: 0.0, y: 0.0, z: 1.0)
    XCTAssertNotNil(pz)
    checkValues (pz!, frame: f1, x: 0.0, y: 0.0, z: 1.0)
    checkAngles (pz!, x: Double.pi/2, y: Double.pi/2, z: 0.0)
    
    let pxyz = Direction (frame: f1, x: 1.0, y: 1.0, z: 1.0)
    let pxyzD = 1/sqrt(3.0)
    let pxyzA = acos (pxyzD)
    XCTAssertNotNil(pxyz)
    checkValues (pxyz!, frame: f1, x: pxyzD, y: pxyzD, z: pxyzD)
    checkAngles (pxyz!, x: pxyzA, y: pxyzA, z: pxyzA)
  }
  
  func testInitDir1Dir2 () {
    let f1 = Frame.root
    let px = Direction (frame: f1, axis: .x)
    let py = Direction (frame: f1, axis: .y)
    let pz = Direction (frame: f1, axis: .z)

    // X x Y -> Z
    let pxyD = Direction (frame: f1, dir1: px, dir2: py)!
    //    checkValues(pxyD, frame: f1, x: pz.coordX, y: pz.coordY, z: pz.coordZ)

    // Y x Z -> X
    let pyzD = Direction (frame: f1, dir1: py, dir2: pz)!
    checkValues(pyzD, frame: f1, x: px.x, y: px.y, z: px.z)

    // Z x X -> Y
    let pzxD = Direction (frame: f1, dir1: pz, dir2: px)!
    checkValues(pzxD, frame: f1, x: py.x, y: py.y, z: py.z)

    // Y x X -> -Z
    let pyxD = Direction (frame: f1, dir1: py, dir2: px)!
    checkValues(pyxD, frame: f1, x: -pz.x, y: -pz.y, z: -pz.z)
    XCTAssertEqual(pxyD.quat.q0, 0.0)
    
    // X x X -> nil
    let pxxD = Direction (frame: f1, dir1: px, dir2: px)
    XCTAssertNil(pxxD)

    // X x -X -> nil
    let pxxiD = Direction (frame: f1, dir1: px, dir2: px.inverse)
    XCTAssertNil(pxxiD)
  }
  
  func testInitRAI () {
    let f1 = Frame.root
    let px = Direction (frame: f1, axis: .x)
    let py = Direction (frame: f1, axis: .y)
    let pz = Direction (frame: f1, axis: .z)
    
    let r  = Quantity<Length> (value: 1.0, unit: meter)
    let a1 = Quantity<Angle>  (value: 0.0, unit: radian)
    let i1 = Quantity<Angle>  (value: Double.pi/2.0, unit: radian)

    let p1 = Direction (frame: f1, radius: r, azimuth: a1, inclination: i1)!
    checkValues(p1, frame: f1, x: px.x, y: px.y, z: px.z)

    let a2 = Quantity<Angle>  (value: Double.pi/2.0, unit: radian)
    let p2 = Direction (frame: f1, radius: r, azimuth: a2, inclination: i1)!
    checkValues(p2, frame: f1, x: py.x, y: py.y, z: py.z)

    let i2 = Quantity<Angle>  (value: 0.0, unit: radian)
    let p3 = Direction (frame: f1, radius: r, azimuth: a1, inclination: i2)!
    checkValues(p3, frame: f1, x: pz.x, y: pz.y, z: pz.z)
    
    let r0 = Quantity<Length> (value: 0.0, unit: meter)
    let p4 = Direction (frame: f1, radius: r0, azimuth: a1, inclination: i1)
    XCTAssertNil(p4)
  }
  
  func testInvert () {
    let f1 = Frame.root
    let px = Direction (frame: f1, axis: .x)
    let pI = px.inverse
    
    checkValues(pI, frame: f1, x: -px.x, y: -px.y, z: -px.z)
  }
  
  func testRotate () {
    
  }
  
  func testPerformanceExample() {
    self.measure {
    }
  }
}
