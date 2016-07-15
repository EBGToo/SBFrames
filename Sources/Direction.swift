//
//  Direction.swift
//  SBFrames
//
//  Created by Ed Gamble on 10/22/15.
//  Copyright © 2015 Edward B. Gamble Jr.  All rights reserved.
//
//  See the LICENSE file at the project root for license information.
//  See the CONTRIBUTORS file at the project root for a list of contributors.
//

import SBUnits
#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
  import Darwin.C.math
#endif

///
/// A Direction represents a direction to a postion defined in a `Frame`.  A Direction can be
/// inverted, rotated and transformed.  The angle between a direction and another direction or an
/// axis can be computed.  A Direction can produce a Position (given a `unit`) and an Orientation
/// (given an `angle` about the direction).
///
/// A Direction is generally immutable.
///
public struct Direction : Framed {
  
  /// The `frame`
  public let frame : Frame
  
  // The quaternion, must be a pure and unit Quaternion
  let quat : Quaternion
  
  /// The (unitless) x coordinate
  public var x : Double { return quat.q1 }
  
  /// The (unitless) y coordinate
  public var y : Double { return quat.q2 }
  
  /// The (unitless) z coordinate
  public var z : Double { return quat.q3 }

  /// The (unitless) coordinate for `axis`
  public func axialCoord (_ axis: Frame.Axis) -> Double {
    switch axis {
    case .x: return quat.q1
    case .y: return quat.q2
    case .z: return quat.q3
    }
  }

  /// The angle between `self` and `that`
  public func includedAngle (_ that: Direction) -> Quantity<Angle> {
    return Quantity<Angle> (value: acos (quat.dot (that.quat)),
                            unit: radian)
  }

  /// The angle between `self` and `axis`
  public func includedAngle (axis: Frame.Axis) -> Quantity<Angle> {
    return Quantity<Angle>(value: acos (axialCoord(axis)),
                           unit: radian)
  }

  /// The position represented by `self` with `unit`.  Will have a distance of '1 unit'.
  public func position (unit: Unit<Length>) -> Position {
    return Position (frame: frame,
                     unit: unit,
                     quat: quat)
  }

  /// An orientation in `self`'s direction with `angle` about `self`.
  public func orientation (angle: Quantity<Angle>) -> Orientation {
    return Orientation (frame: frame,
                        angle: angle,
                        direction: self)
  }
  
  // MARK: Initialize
  
  ///
  /// Initalize from cartesian coordiantes { x, y, z }
  ///
  /// - parameter frame:
  /// - parameter x:
  /// - parameter y:
  /// - parameter z:
  ///
  public init? (frame:Frame, x: Double, y: Double, z:Double) {
    guard let quat = Quaternion(q0: 0.0, q1: x, q2: y, q3: z).normalize else { return nil }

    self.init (frame: frame, quat: quat)
  }

  ///
  /// Initialize based on spherical coordinates of { radium, aximuth, inclination }
  ///
  /// - parmeter frame:
  /// - parameter radius:
  /// - parameter aximuth:
  /// - parameter inclination:
  ///
  public init? (frame: Frame, radius: Quantity<Length>, azimuth: Quantity<Angle>, inclination: Quantity<Angle>) {
    guard !radius.value.isZero else { return nil }
    
    self = Position (frame: frame, radius: radius, azimuth: azimuth, inclination: inclination).direction!
  }

  ///
  /// Initialize based on cylindrical coordinates of { radius, aximuth, height }
  ///
  /// - parmeter frame:
  /// - parameter radius:
  /// - parameter aximuth:
  /// - parameter height:
  ///
  public init? (frame: Frame, radius: Quantity<Length>, azimuth: Quantity<Angle>, height: Quantity<Length>) {
    guard !radius.value.isZero else { return nil }
    
    self = Position (frame: frame, radius: radius, azimuth: azimuth, height: height).direction!
  }

  ///
  /// Initialize along `axis`
  ///
  /// - parameter frame:
  /// - parameter axis:
  ///
  public init (frame:Frame, axis: Frame.Axis) {
    var x = 0.0, y = 0.0, z = 0.0
    
    switch axis {
    case .x: x = 1.0
    case .y: y = 1.0
    case .z: z = 1.0
    }

    self.init (frame: frame, quat: Quaternion (q0: 0.0, q1: x, q2: y, q3: z))
  }

  ///
  /// Initilzie along the 'z' axis
  ///
  /// - parameter frame:
  ///
  public init (frame: Frame) {
    self.init (frame: frame, axis: .z)
  }

  ///
  /// Initilize as dir1 x dir2 (perpendicular to dir1 and dir2) or nil if dir1/dir2 are parallel.
  ///
  /// - parameter frame:
  /// - parameter dir1:
  /// - parameter dir2:
  ///
  public init? (frame: Frame, dir1: Direction, dir2: Direction) {
    // d1 x d2 => q1 * q2 => q2.compose(q1)
    let quatCross = dir1.quat * dir2.quat
    
    // When dir1 and dir2 are parallel the quatCross's direction will be zero (q0 is +-1.0)
    guard !(quatCross.q1.isZero && quatCross.q2.isZero && quatCross.q3.isZero) else { return nil }
    
    self.init (frame: frame,
               quat: quatCross)
  }
  
  ///
  /// Initialize with `quat`
  ///
  /// - parameter frame:
  /// - parameter quat:
  ///
  init (frame: Frame, quat: Quaternion) {
    self.frame = frame
    self.quat = quat
  }
}

// MARK: Equatable

///
///
///
extension Direction : Equatable {
  public static func == (lhs: Direction, rhs: Direction) -> Bool {
    return lhs.frame == rhs.frame &&
      lhs.quat == rhs.quat
  }
}

// MARK: Invertable

extension Direction : Invertable {
  public var inverse : Direction {
    return Direction (frame: frame, quat: quat.conjugate)
  }
}

// MARK: Rotatable

extension Direction : Rotatable {
  public func rotate (_ offset: Orientation) -> Direction {
    
    // Convert `offset` to frame then get the quaternion
    let offset = offset.transform (to: frame)
    
    return Direction (frame: frame,
                      quat: quat.rotate (by: offset.quat))
  }
}

// MARK: Transformable

extension Direction : Transformable {
  
  public func transform (to frame: Frame) -> Direction {
    guard self.frame !== frame else { return self }
    
    let asPosition = self.position (unit: meter)
    
    return Frame (position: asPosition).transform (to: frame).position.direction!
  }
  
  
  // Transform `self` by frame to produce a new `framed` that will have a *different* physical
  // position and orientation.
  public func transform (by frame: Frame) -> Direction {
    let position = self.position (unit: meter)
    
    return Frame (position: position).transform(by: frame).position.direction!
  }
}
