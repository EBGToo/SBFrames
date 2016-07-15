//
//  PositionTest.swift
//  SBFrames
//
//  Created by Ed Gamble on 6/15/16.
//  Copyright © 2016 Edward B. Gamble Jr.  All rights reserved.
//
//  See the LICENSE file at the project root for license information.
//  See the CONTRIBUTORS file at the project root for a list of contributors.
//

import XCTest
import SBUnits

@testable import SBFrames

class PositionTest: XCTestCase {
  
  let accuracy = Quaternion.epsilon
  
  override func setUp() {
    super.setUp()
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
  
  func testInit() {
    let f1 = Frame.root

    let p1 = Position (frame:f1)
    checkValues (p1, frame: f1, unit: meter, x: 0.0, y: 0.0, z: 0.0)
   
    let px = Position (frame: f1,  unit: meter, x: 1.0, y: 0.0, z: 0.0)
    checkValues (px, frame: f1, unit: meter, x: 1.0, y: 0.0, z: 0.0)
    
    let py = Position (frame: f1,  unit: meter, x: 0.0, y: 1.0, z: 0.0)
    checkValues (py, frame: f1, unit: meter, x: 0.0, y: 1.0, z: 0.0)

    let pz = Position (frame: f1,  unit: meter, x: 0.0, y: 0.0, z: 1.0)
    checkValues (pz, frame: f1, unit: meter, x: 0.0, y: 0.0, z: 1.0)
  }
  
  func testInvert () {
    let f1 = Frame.root
    
    let px = Position (frame: f1,  unit: meter, x: 1.0, y: 0.0, z: 0.0)
    checkValues (px, frame: f1, unit: meter, x: 1.0, y: 0.0, z: 0.0)
    
    let pxi = px.inverse
    checkValues (pxi, frame: f1, unit: meter, x: -1.0, y: 0.0, z: 0.0)
    
    let pxl = Position (frame: f1, unit: meter, x: 1.0, y: 1.0, z: 1.0).inverse
    checkValues (pxl, frame: f1, unit: meter, x: -1.0, y: -1.0, z: -1.0)
  }
  
  func testTranslate () {
    let f1 = Frame.root
    
    let px = Position (frame: f1,  unit: meter, x: 1.0, y: 0.0, z: 0.0)
    checkValues (px, frame: f1, unit: meter, x: 1.0, y: 0.0, z: 0.0)
    
    let pxt1 = px.translate(Position (frame: f1, unit: meter, x: 0.0, y: 1.0, z: 0.0))
    checkValues (pxt1, frame: f1, unit: meter, x: 1.0, y: 1.0, z: 0.0)

    let pxt2 = px.translate(pxt1.inverse)
    checkValues (pxt2, frame: f1, unit: meter, x: 0.0, y: -1.0, z: 0.0)
    
  }
  
  func testTranslateUnits () {
    let f1 = Frame.root
    
    let px = Position (frame: f1,  unit: meter, x: 1.0, y: 0.0, z: 0.0)
    checkValues (px, frame: f1, unit: meter, x: 1.0, y: 0.0, z: 0.0)
    
    let pxt1 = px.translate(Position (frame: f1, unit: millimeter, x: -1000.0, y: 0.0, z: 0.0))
    checkValues (pxt1, frame: f1, unit: meter, x: 0.0, y: 0.0, z: 0.0)
  }
  
  
  func testRotate () {
    let f1 = Frame.root
    
    let px = Position (frame: f1,  unit: meter, x: 1.0, y: 0.0, z: 0.0)
    checkValues (px, frame: f1, unit: meter, x: 1.0, y: 0.0, z: 0.0)
    
    //
    let r1 = Orientation (frame: f1,
                          angle: Quantity<Angle>(value: Double.pi / 2, unit: radian),
                          axis: .z)
    
    let pxr1 = px.rotate(r1)
    checkValues(pxr1, frame: f1, unit: meter, x: 0.0, y: 1.0, z: 0.0)

    //
    let r2 = Orientation (frame: f1,
                          angle: Quantity<Angle>(value: 2 * Double.pi, unit: radian),
                          axis: .z)
    
    let pxr2 = px.rotate(r2)
    checkValues(pxr2, frame: f1, unit: meter, x: 1.0, y: 0.0, z: 0.0)

    // Rotate around: z, x, and y by pi/2 -> back to self
    let rz = Orientation (frame: f1,
                          angle: Quantity<Angle>(value: Double.pi / 2, unit: radian),
                          axis: .z)
    
    let rx = Orientation (frame: f1,
                          angle: Quantity<Angle>(value: Double.pi / 2, unit: radian),
                          axis: .x)
    let ry = Orientation (frame: f1,
                          angle: Quantity<Angle>(value: Double.pi / 2, unit: radian),
                          axis: .y)
    
    let pxrxyz = px.rotate(rz).rotate(rx).rotate(ry)
    checkValues(pxrxyz, frame: f1, unit: meter, x: 1.0, y: 0.0, z: 0.0)
  }
  
  func testDistance () {
    let f1 = Frame.root
    
    let px = Position (frame: f1,  unit: meter, x: 1.0, y: 0.0, z: 0.0)
    checkValues (px, frame: f1, unit: meter, x: 1.0, y: 0.0, z: 0.0)
    XCTAssertEqual(px.distance.value, 1.0)
    
    let pxt1 = px.translate(Position (frame: f1, unit: meter, x: 0.0, y: 1.0, z: 0.0))
    checkValues (pxt1, frame: f1, unit: meter, x: 1.0, y: 1.0, z: 0.0)
    XCTAssertEqual(pxt1.distance.value, sqrt (2.0))
    
    XCTAssertEqual(pxt1.distanceBetween(px).value, 1.0)
    XCTAssertEqual(px.distanceBetween(pxt1).value, 1.0)
  }
  
  func testDirection () {
    let f1 = Frame.root
    
    let px = Position (frame: f1,  unit: meter, x: 2.0, y: 0.0, z: 0.0)
    checkValues (px, frame: f1, unit: meter, x: 2.0, y: 0.0, z: 0.0)
    
    let dx = px.direction
    XCTAssertNotNil (dx)
    XCTAssertEqual(dx!.x, 1.0, accuracy: accuracy)
    XCTAssertEqual(dx!.y, 0.0, accuracy: accuracy)
    XCTAssertEqual(dx!.z, 0.0, accuracy: accuracy)

    let pxy = Position (frame: f1,  unit: meter, x: 2.0, y: 2.0, z: 0.0)
    checkValues (pxy, frame: f1, unit: meter, x: 2.0, y: 2.0, z: 0.0)
    
    let dxy = pxy.direction
    XCTAssertNotNil (dxy)
    XCTAssertEqual(dxy!.x, 1 / sqrt (2.0), accuracy: accuracy)
    XCTAssertEqual(dxy!.y, 1 / sqrt (2.0), accuracy: accuracy)
    XCTAssertEqual(dxy!.z, 0.0, accuracy: accuracy)

    let p0 = Position (frame: f1,  unit: meter, x: 0.0, y: 0.0, z: 0.0)
    checkValues (p0, frame: f1, unit: meter, x: 0.0, y: 0.0, z: 0.0)
    
    let d0 = p0.direction
    XCTAssertNil (d0)

  }
  
  func testScale () {
    let f1 = Frame.root
    
    let px = Position (frame: f1,  unit: meter, x: 1000.0, y: 0.0, z: 0.0)
    checkValues (px, frame: f1, unit: meter, x: 1000.0, y: 0.0, z: 0.0)

    let py = Position (frame: f1,  unit: kilometer, x: 1.0, y: 0.0, z: 0.0)
    checkValues (py, frame: f1, unit: kilometer, x: 1.0, y: 0.0, z: 0.0)
    
    XCTAssertEqual(px, py.scale(for: meter))
  }
  
  func testRIA () {
    
  }
  
  func testRAH () {
    
  }
  
  func testTransformedTo () {
    
  }
  
  func testTransformto () {
    
  }
  
  func testTransformBy () {
    
  }
  
  func testMutable () {
    let p1 = Position (frame: Frame.root,  unit: meter, x: 1.0, y: 0.0, z: 0.0)
    var p2 = p1
    checkValues (p1, frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0)
    checkValues (p2, frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0)

    let off1 = Position (frame: Frame.root,  unit: meter, x: -2.0, y: 0.0, z: 0.0)
    
    // Translate p2; ensure p1 is unchanged.
    p2.translated(off1)
    checkValues (p1, frame: Frame.root, unit: meter, x:  1.0, y: 0.0, z: 0.0)
    checkValues (p2, frame: Frame.root, unit: meter, x: -1.0, y: 0.0, z: 0.0)
  }
  
  func testPerformanceExample() {
    self.measure {
    }
  }
}
