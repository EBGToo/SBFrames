//
//  FrameTest.swift
//  SBFrames
//
//  Created by Ed Gamble on 6/26/16.
//  Copyright © 2016 Edward B. Gamble Jr.  All rights reserved.
//
//  See the LICENSE file at the project root for license information.
//  See the CONTRIBUTORS file at the project root for a list of contributors.
//

import XCTest
import SBUnits
@testable import SBFrames

class FrameTest: XCTestCase {

  let accuracy = Quaternion.epsilon

  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }

  func checkPosition (_ p: Position, frame: Frame, unit: SBUnits.Unit<Length>, x: Double, y: Double, z: Double) {
    //    XCTAssert(p.has (frame: frame))
    XCTAssertEqual(p.x.value, x, accuracy: accuracy)
    XCTAssertEqual(p.y.value, y, accuracy: accuracy)
    XCTAssertEqual(p.z.value, z, accuracy: accuracy)
    
    XCTAssertTrue(p.x.unit === unit)
    XCTAssertTrue(p.y.unit === unit)
    XCTAssertTrue(p.z.unit === unit)
    
    XCTAssertTrue(p.unit === unit)
    XCTAssertEqual(p.unit, unit)
  }
  
  func checkOrientation (_ o: Orientation, frame: Frame, angle: Quantity<Angle>, axis: Frame.Axis) {
    let oq = o.quat
    let aq = Orientation (frame: frame, angle: angle, axis: axis).quat
    
    XCTAssertEqual(oq.q0, aq.q0, accuracy: accuracy)
    XCTAssertEqual(oq.q1, aq.q1, accuracy: accuracy)
    XCTAssertEqual(oq.q2, aq.q2, accuracy: accuracy)
    XCTAssertEqual(oq.q3, aq.q3, accuracy: accuracy)
}

  func testFrame1() {
    let f1 = Frame (position: Frame.root.translation(unit: meter, x: 0.0, y: 0.0, z: 1.0))
    let pr1 = f1.position.quat
    
    XCTAssertEqual(f1.frame, Frame.root)
    XCTAssertTrue(f1.has(frame: Frame.root))
    XCTAssertTrue(f1.has(ancestor: Frame.root))
    
    XCTAssertEqual(pr1.q0, 0.0)
    XCTAssertEqual(pr1.q1, 0.0)
    XCTAssertEqual(pr1.q2, 0.0)
    XCTAssertEqual(pr1.q3, 1.0)
  }
  
  func testPosition () {
    let p1 = Frame.root.translation(unit: meter, x: 1.0, y: 0.0, z: 0.0)
    
    XCTAssertEqual(p1.axialCoord(.x), 1.0)
    XCTAssertEqual(p1.axialCoord(.y), 0.0)
    XCTAssertEqual(p1.axialCoord(.z), 0.0)
  }
  
  func testTransformTranslate () {
    
    // Frame f1x at { 1, 0, 0 }
    let f1x = Frame (position: Position (frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0))

    // Frame f2x at { 2, 0, 0 } in f1x
    let f2x = Frame (position: Position (frame: f1x, unit: meter, x: 2.0, y: 0.0, z: 0.0))

    // Frame f2x_to_r at { 3, 0, 0 }
    let f2x_to_r = f2x.transform(to: Frame.root)
    checkPosition(f2x_to_r.position, frame: Frame.root, unit: meter, x: 3.0, y: 0.0, z: 0.0)
    
    // Frame f2x at { 0, 2, 1 } in f2x
    let f3x = Frame (position: Position (frame: f2x, unit: meter, x: 0.0, y: 2.0, z: 1.0))

    // Frame f3x_to_r at { 3, 2, 1 }
    let f3x_to_r = f3x.transform(to: Frame.root)
    checkPosition(f3x_to_r.position, frame: Frame.root, unit: meter, x: 3.0, y: 2.0, z: 1.0)
}
  
  func testTransformRotate () {
    
    // Frame f1x at {root, rotZ 90}
    let f1x = Frame (orientation: Orientation (frame: Frame.root,
                                               angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                                               axis: .z ))
    
    // Frame f2x at {f1x, rotZ 90}
    let f2x = Frame (orientation: Orientation (frame: f1x,
                                               angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                                               axis: .z ))
        
    let f2x_to_1 = f2x.transform(to: Frame.root)
    checkOrientation(f2x_to_1.orientation, frame: Frame.root,
                     angle: Quantity<Angle>(value: Double.pi, unit: radian),
                     axis: .z)
    
    // Frame f3x at f2x.invert :: {f1x, - rotZ 90}
    let f3x = Frame (orientation: Orientation (frame: f1x,
                                               angle: Quantity<Angle>(value: -Double.pi/2, unit: radian),
                                               axis: .z ))
    
    let f3x_to_1 = f3x.transform(to: Frame.root)
    checkOrientation(f3x_to_1.orientation, frame: Frame.root,
                     angle: Quantity<Angle>(value: 0.0, unit: radian),
                     axis: .z)

    // Frame f3x at f2x.invert :: {f1x, - rotZ 90}
    let f4x = f2x.inverse
      
    let f4x_to_1 = f4x.transform(to: Frame.root)
    checkOrientation(f4x_to_1.orientation, frame: Frame.root,
                     angle: Quantity<Angle>(value: 0.0, unit: radian),
                     axis: .z)
  }
  
  func testTranformOne () {
    // Frame f1x at {root, pos 1.0}
    let f1x = Frame (position: Position (frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0))
    
    // Frame f2x at {f1x, rotZ90}
    let f2x = Frame (orientation: Orientation (frame: f1x,
                                               angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                                               axis: .z ))

    let f2x_to_1 = f2x.transform(to: Frame.root)
    checkOrientation(f2x_to_1.orientation, frame: Frame.root,
                     angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                     axis: .z)
    checkPosition(f2x_to_1.position, frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0)
  }
  
  func testTranformTwo () {
    // Frame f1x at {root, rotZ90}
    let f1x = Frame (orientation: Orientation (frame: Frame.root,
                                               angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                                               axis: .z ))
    
    // Frame f2x at {f1x, pos 1.0}
    let f2x = Frame (position: Position (frame: f1x, unit: meter, x: 1.0, y: 0.0, z: 0.0))
    
    let f2x_to_1 = f2x.transform(to: Frame.root)
    checkOrientation(f2x_to_1.orientation, frame: Frame.root,
                     angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                     axis: .z)
    checkPosition(f2x_to_1.position, frame: Frame.root, unit: meter, x: 0.0, y: 1.0, z: 0.0)
  }

  func testTranformTre () {
    // Frame f1x at {root, pos 1.0}
    let f1x = Frame (position: Position (frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0))
    
    // Frame f2x at {f1x, rotZ90}
    let f2x = Frame (frame: f1x,
                     position: Position (frame: f1x, unit: meter, x: 0.0, y: 2.0, z: 0.0),
                     orientation: Orientation (frame: f1x,
                                               angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                                               axis: .z ))
    
    let f2x_to_1 = f2x.transform(to: Frame.root)
    checkOrientation(f2x_to_1.orientation, frame: Frame.root,
                     angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                     axis: .z)
    checkPosition(f2x_to_1.position, frame: Frame.root, unit: meter, x: 1.0, y: 2.0, z: 0.0)
  }

  func testTransformFor () {
    // Frame f1x at {root, rotZ90}
    let f1x = Frame (frame: Frame.root,
                     position: Position (frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0),
                     orientation: Orientation (frame: Frame.root,
                                               angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                                               axis: .z ))
    
    // Frame f2x at {f1x, pos 1.0}
    let f2x = Frame (position: Position (frame: f1x, unit: meter, x: 2.0, y: 0.0, z: 0.0))
    
    let f2x_to_1 = f2x.transform(to: Frame.root)
    checkOrientation(f2x_to_1.orientation, frame: Frame.root,
                     angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                     axis: .z)
    checkPosition(f2x_to_1.position, frame: Frame.root, unit: meter, x: 1.0, y: 2.0, z: 0.0)
  }
  
  //
  // Inverse Transforms
  //
  
  func testTranslateInverse () {
    
    // Frame f1x at { 1, 0, 0 }
    let f1 = Frame (position: Position (frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0))
    
    // Position p2x at { 1, 0, 0 } in f1x
    let f2 = Frame (position: Position (frame: f1, unit: meter, x: 2.0, y: 0.0, z: 0.0))
    
    let f1_to_f2 = f1.transform(to: f2)
    checkPosition(f1_to_f2.position, frame: f2, unit: meter, x: -2.0, y: 0.0, z: 0.0)
    
    let f3 = Frame (position: Position (frame: f2, unit: meter, x: 3.0, y: 0.0, z: 0.0))
    let f4 = Frame (position: Position (frame: f3, unit: meter, x: 4.0, y: 0.0, z: 0.0))

    let f4_to_f1 = f4.transform(to: f1)
    checkPosition(f4_to_f1.position, frame: f4, unit: meter, x: 9.0, y: 0.0, z: 0.0)
    
    let f1_to_f4 = f1.transform (to: f4)
    checkPosition(f1_to_f4.position, frame: f4, unit: meter, x: -9.0, y: 0.0, z: 0.0)
  }
  
  func testTranslateInverseTwo () {
    
    // Frame f1x at { 1, 0, 0 }
    let f1 = Frame (position: Position (frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0))
    checkPosition(f1.position, frame: f1, unit: meter, x: 1.0, y: 0.0, z: 0.0)
    
    // Position p2x at { 1, 0, 0 } in f1x
    let f2 = Frame (position: Position (frame: f1, unit: meter, x: 2.0, y: 0.0, z: 0.0))
    checkPosition(f2.position, frame: f2, unit: meter, x: 2.0, y: 0.0, z: 0.0)
    let f2_to_f1 = f2.transform(to: f1)
    checkPosition(f2_to_f1.position, frame: f1, unit: meter, x: 2.0, y: 0.0, z: 0.0)
    
    let f3 = Frame (position: Position (frame: f1, unit: meter, x: -2.0, y: 0.0, z: 0.0))
    checkPosition(f3.position, frame: f3, unit: meter, x: -2.0, y: 0.0, z: 0.0)
    let f3_to_f1 = f3.transform(to: f1)
    checkPosition(f3_to_f1.position, frame: f1, unit: meter, x: -2.0, y: 0.0, z: 0.0)

    XCTAssertTrue(f1 === f2.common (f3))

    let f3_to_f2 = f3.transform(to: f2)
    checkPosition(f3_to_f2.position, frame: f2, unit: meter, x: -4.0, y: 0.0, z: 0.0)
  }
  
  func testRotateInverse () {
    
    // Frame f1x at {root, rotZ 90}
    let f1 = Frame (orientation: Orientation (frame: Frame.root,
                                               angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                                               axis: .z ))
    
    // Frame f2x at {f1x, rotZ 90}
    let f2 = Frame (orientation: Orientation (frame: f1,
                                               angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                                               axis: .z ))
    
    let f1_to_2 = f1.transform(to: f2)
    checkOrientation(f1_to_2.orientation, frame: Frame.root,
                     angle: Quantity<Angle>(value: -Double.pi/2, unit: radian),
                     axis: .z)
  }
  
  func testTransformByOne () {
    // Frame f1x at {root, rotZ 90}
    let f1 = Frame (orientation: Orientation (frame: Frame.root,
                                              angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                                              axis: .z ))
    
    let f1inc = Frame (orientation: Orientation (frame: Frame.root,
                                                 angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                                                 axis: .z ))
    
    let f2 = f1.transform(by: f1inc)
    checkPosition(f2.position, frame: Frame.root, unit: meter, x: 0.0, y: 0.0, z: 0.0)
    checkOrientation(f2.orientation, frame: Frame.root,
                     angle: Quantity<Angle>(value: Double.pi, unit: radian),
                     axis: .z)
  }
  
  func testTransformByTwo () {
    // Frame f1x at {root, rotZ 90}
    let f1 = Frame (orientation: Orientation (frame: Frame.root,
                                              angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                                              axis: .z ))
    
    let f1inc = Frame (position: Frame.root.translation(unit: meter, x: 1.0, y: 0.0, z: 0.0))
    
    let f2 = f1.transform(by: f1inc)
    checkPosition(f2.position, frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0)
    checkOrientation(f2.orientation, frame: Frame.root,
                     angle: Quantity<Angle>(value: Double.pi/2, unit: radian),
                     axis: .z)
  }
  
  func testMutableSharedReference () {
    let f1 = Frame (position: Position (frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0))
    let f2 = f1
    checkPosition(f1.position, frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0)
    checkPosition(f2.position, frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0)
 
    let off1 = Position (frame: Frame.root,  unit: meter, x: -2.0, y: 0.0, z: 0.0)

    // F2 mutated, F1 also
    f2.translated(off1)

    checkPosition(f1.position, frame: Frame.root, unit: meter, x: -1.0, y: 0.0, z: 0.0)
    checkPosition(f2.position, frame: Frame.root, unit: meter, x: -1.0, y: 0.0, z: 0.0)
  }

  func testMutableParent () {
    let f1 = Frame (position: Position (frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0))
    checkPosition(f1.position, frame: Frame.root, unit: meter, x: 1.0, y: 0.0, z: 0.0)

    let f2 = Frame (frame: f1,
                    position: Position (frame: f1, unit: meter, x: 1.0, y: 0.0, z: 0.0),
                    orientation: Orientation (frame: f1))
    checkPosition(f2.position, frame: f2, unit: meter, x: 1.0, y: 0.0, z: 0.0)
    checkPosition(f2.position.transform(to: Frame.root),
                  frame: Frame.root,
                  unit: meter,
                  x: 2.0, y: 0.0, z: 0.0)

    
    let off1 = Position (frame: Frame.root, unit: meter, x: -2.0, y: 0.0, z: 0.0)
    
    // F1 mutated, F2 is too
    f1.translated(off1)

    checkPosition(f1.position,
                  frame: Frame.root,
                  unit: meter,
                  x: -1.0, y: 0.0, z: 0.0) // 1.0 => -1.0

    checkPosition(f2.position, frame: f2, unit: meter, x:  1.0, y: 0.0, z: 0.0)
    checkPosition(f2.position.transform(to: Frame.root),
                  frame: Frame.root,
                  unit: meter,
                  x: 0.0, y: 0.0, z: 0.0)  // 2.0 => 0.0
  }

  func testPerformanceExample() {
    self.measure {
    }
  }
}
