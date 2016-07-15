//
//  Position.swift
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
/// A Position represents a 3d spatial position in a 3D cartesian coordinate system defined by a
/// `frame`.  A Position adhers to the `Framed` protocol and can be scaled, translated, rotated, 
/// inverted and transformed.  A Position can be converted into a `Direction`.  With two Positions
/// one can computate the distance and angle between the two postions; if the two positions are in
/// a different frame, then they are converted to the same frame before the desired computation.
///
/// A Position is generally immutable.
///
public struct Position : Framed {

  /// The frame of `self
  public let frame : Frame

  /// The unit of `self`.
  public let unit : Unit<Length>

  /// The internal representation of `self` - a pure quaternion (q0 == 0), un-normalized.
  let quat : Quaternion

  /// The x coordinate in `unit`
  public var x : Quantity<Length> { return axialDistance(Frame.Axis.x) }
  
  /// The y coordinate in `unit`
  public var y : Quantity<Length> { return axialDistance(Frame.Axis.y) }
  
  /// The z coordinate in `unit`
  public var z : Quantity<Length> { return axialDistance(Frame.Axis.z) }
  
  /// The coordinate along `axis`
  internal func axialCoord (_ axis: Frame.Axis) -> Double {
    switch axis {
    case .x: return quat.q1
    case .y: return quat.q2
    case .z: return quat.q3
    }
  }
  
  /// The distance along `axis`
  public func axialDistance (_ axis: Frame.Axis) -> Quantity<Length> {
    return Quantity<Length> (value: axialCoord (axis), unit: unit)
  }

  /// The distance from the origin
  public var distance : Quantity<Length> {
    return Quantity<Length> (value: quat.norm, unit: unit)
  }

  ///
  /// The distance between `self` and `that`
  ///
  /// - note: `that` will be scaled for `unit`
  ///
  public func distanceBetween (_ that: Position) -> Quantity<Length> {
    return self.translate(that.scale(for: unit).inverse).distance
  }

  ///
  /// The angle between `self` and `that`
  ///
  /// - note: We do not need to scale `that` into `unit`
  ///
  public func angleBetween (_ that: Position) -> Quantity<Angle>? {
    // Compute norms
    let normOfSelf = self.quat.norm
    let normOfThat = that.quat.norm
    
    // Ensure neither norm is zero
    guard !normOfSelf.isZero && !normOfThat.isZero else { return nil }

    // Compute the angle
    return Quantity<Angle> (value: acos (self.quat.dot(that.quat) / normOfSelf / normOfThat),
                            unit: radian)
  }
  
  /// The direction
  public var direction : Direction? {
    return Direction (frame: frame, x: quat.q1, y: quat.q2, z: quat.q3)
  }
  
  ///
  /// Scale `self` by `factor`
  ///
  public func scale (_ factor: Double) -> Position {
    return Position (frame: frame,
                     unit: unit,
                     quat: factor * quat)
  }
  
  ///
  /// Scale `self` for `unit`.  The returned Postion corresponds to the same position in frame but
  /// is represented with `unit`
  ///
  public func scale (for unit: Unit<Length>) -> Position {
    guard self.unit !== unit else { return self }
    
    let converter = Unit.converter (self.unit, unit)
    
    return Position (frame: frame, unit: unit,
                     x: converter (quat.q1),
                     y: converter (quat.q2),
                     z: converter (quat.q3))
  }
  
  ///
  /// Modify `self` by scaling for `unit`.  The resulting `self` corresponds to the same position 
  /// in frame but is represented with `unit`
  ///
  public mutating func scaled (for unit: Unit<Length>) {
    self = scale (for: unit)
  }
  
  
  // MARK: Initialize
  
  ///
  /// Initialize based on cartesian coordiantes of { x, y, z } for `unit`.
  ///
  /// - parameter frame:
  /// - parameter unit:
  /// - parameter x:
  /// - parameter y:
  /// - parameter z:
  ///
  public init (frame: Frame, unit: Unit<Length>, x: Double, y: Double, z: Double) {
    self.init (frame: frame,
               unit: unit,
               quat: Quaternion (q0: 0.0, q1: x, q2: y, q3: z))
  }
  
  ///
  /// Initialize based on spherical coordinates of { radium, aximuth, inclination }
  ///
  /// - parameter frame:
  /// - parameter radius:
  /// - parameter azimuth:
  /// - parameter inclination:
  ///
  public init (frame: Frame, radius: Quantity<Length>, azimuth: Quantity<Angle>, inclination: Quantity<Angle>) {
    let r     = radius.value
    let theta = radian.convert(inclination.value, unit: inclination.unit)
    let phi   = radian.convert(azimuth.value, unit: azimuth.unit)
    
    self.init (frame: frame, unit: radius.unit,
               x: r * sin(theta) * cos(phi),
               y: r * sin(theta) * sin(phi),
               z: r * cos(theta))
  }
  
  ///
  /// Initialize based on cylindrical coordinates of { radius, aximuth, height }
  ///
  /// - parameter frame:
  /// - parameter radius:
  /// - parameter azimuth:
  /// - parameter height:
  ///
  public init (frame: Frame, radius: Quantity<Length>, azimuth: Quantity<Angle>, height: Quantity<Length>) {
    let r = radius.value
    let phi   = radian.convert(azimuth.value, unit: azimuth.unit)
    let h = radius.unit.convert(height.value, unit: height.unit)
    
    self.init (frame: frame, unit: radius.unit,
               x: r * cos(phi),
               y: r * sin(phi),
               z: h)
  }
  
  ///
  /// Initialize
  ///
  /// - parameter frame:
  ///
  public init (frame: Frame) {
    self.init (frame: frame,
               unit: meter,
               quat: Quaternion ())
  }
  
  ///
  /// Initialize
  ///
  /// - parameter frame:
  /// - parameter unit:
  /// - parameter quat:
  ///
  internal init (frame: Frame, unit: Unit<Length>, quat: Quaternion) {
    self.quat = quat
    self.unit = unit
    self.frame = frame
  }
}

///
///
///
extension Position : Equatable {
  public static func == (lhs: Position, rhs: Position) -> Bool {
    return lhs.frame == rhs.frame &&
      lhs.unit == rhs.unit &&
      lhs.quat == rhs.quat
  }
}
// MARK: Invertable

extension Position : Invertable {
  ///
  /// Invert `self`.  Returns a postion such that 0 == self.translate(self.invert)
  ///
  public var inverse : Position {
    return Position (frame: frame, unit: unit, quat: quat.conjugate)
  }
}

// MARK: Translatable

extension Position : Translatable {
  ///
  /// Translate `self` by `offset` to produce a new position.  If `offset` is not in the frame
  /// of `self` then `offset` is transformed into `self`'s frame.  Additionally, `offset` is
  /// scaled for `unit`.
  ///
  public func translate (_ offset: Position) -> Position {
    
    // Convert
    let offset = offset.transform (to: frame).scale(for: unit)
    
    return Position (frame: frame,
                     unit: unit,
                     quat: quat.translate (by: offset.quat))
  }
}

// MARK: Rotatable

extension Position : Rotatable {
  ///
  /// Rotate `self` by `offset` to produce a new position.  If `offset` is not in the frame
  /// of `self` then `offset` is transformed into `self`'s frame.
  ///
  public func rotate (_ offset: Orientation) -> Position {
    
    // Convert `offset` to frame
    let offset = offset.transform (to: frame)
    
    return Position (frame: frame,
                     unit: unit,
                     quat: quat.rotate (by: offset.quat))
  }
}

// MARK: Transformable

extension Position : Transformable {
  ///
  /// Transform `self` into `frame`.  The resulting Position will represent the *same* physical
  /// position and orientation; it will just be represented in the provided frame.
  ///
  /// This is 'rotate the coordinate system' (not 'rotate the physical body')
  ///
  /// - note: should this not also handle units?
  ///
  public func transform (to frame: Frame) -> Position {
    guard self.frame !== frame else { return self }
    
    // Apply the transformation - inefficiently
    return Frame (position: self).transform (to: frame).position // scale
  }
  
  ///
  /// Transform `self` by frame to produce a new `framed` that will have a *different* physical
  /// position and orientation.
  ///
  /// This is 'rotate the physical body' (not 'rotate the coordinate system).
  ///
  public func transform (by frame: Frame) -> Position {
    
    // Put `frame` into our frame
    let frame = frame.transform (to: self.frame)
    
    // Apply the transformation - inefficiently
    return Frame (position: self).transform (by: frame).position // scale
  }
}

// MARK: Composable

extension Position : Composable {
  ///
  /// Compose `self` and `that`
  ///
  public func compose (_ that: Position) -> Position {
    return translate(that)
  }
}

