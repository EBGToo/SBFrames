//
//  Orientation.swift
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
/// An Orientation represents the axes in a 3D cartesian coordinate system defined by a `frame.`  An
/// Orientation adhers to the `Framed` protocol and can be rotated, inverted and transformed.
///
/// An Orientation is generally immmutable.

public struct Orientation : Framed {

  ///
  /// Enumeration of possible rotation conventions used when constructing and extracting
  /// orientation angles.  The `eulerZYZ` convention produces (raw, pitch, roll) angles.
  ///
  public enum RotationConvention {
    case fixedXYZ
    case eulerZYX // (yaw, pitch, roll)
  }

  /// The `frame` of `self`
  public let frame : Frame

  /// The `quaternion` representation for `self`
  let quat : Quaternion

  ///
  /// Return the (yaw, pitch, roll) angles in radians
  ///
  /// - returns: triple of angles, in radians
  ///
  public var asYawPitchRoll : (yaw:Double, pitch:Double, roll:Double) {
    return quat.asYawPitchRoll
  }

  ///
  /// Return a triple of angles according to `convention`.
  ///
  /// - parameter convention: the rotation convention
  ///
  /// - returns: triple of angles, in radians.
  ///
  public func asAnglesFor (convention: RotationConvention) -> (x:Double, y:Double, z:Double) {
    let (yaw, pitch, roll) = quat.asYawPitchRoll

    switch convention {
    case .fixedXYZ:
      return (x: roll, y: pitch, z: yaw)

    case .eulerZYX:
      return (x: yaw, y: pitch, z: roll)
    }
  }

  // MARK: Initialize

  /// Initialize from a `frame` and a `quat`.
  internal init (frame: Frame, quat: Quaternion) {
    self.quat = quat
    self.frame = frame
  }

  /// Initialize from a `frame`, an `angle` and a `direction`.
  public init (frame: Frame, angle: Quantity<Angle>, direction: Direction) {
    let angle = angle.convert(radian).value
    
    let sin_angle_over_2 = sin (angle / 2.0)
    let cos_angle_over_2 = cos (angle / 2.0)
    
    self.init (frame: frame,
               quat: Quaternion (q0: cos_angle_over_2,
                                 q1: sin_angle_over_2 * direction.x,
                                 q2: sin_angle_over_2 * direction.y,
                                 q3: sin_angle_over_2 * direction.z));
  }

  /// Initialize from a `frame`, an `angle`, and an `axis`.
  public init (frame: Frame, angle: Quantity<Angle>, axis: Frame.Axis) {
    self.init (frame: frame, angle: angle, direction: Direction(frame: frame, axis: axis))
  }

  /// Initialize from a `frame` and `yaw`, `pitch`, and `roll` angles in `unit`
  public init (frame: Frame, unit: Unit<Angle>, yaw: Double, pitch: Double, roll: Double) {
    let   yaw = radian.convert (  yaw, unit: unit)
    let pitch = radian.convert (pitch, unit: unit)
    let  roll = radian.convert ( roll, unit: unit)

    self.init (frame: frame,
               quat: Quaternion.makeAsYawPitchRoll(yaw: yaw, pitch: pitch, roll: roll))
  }

  /// Initialize from Euler or Fixed XYZ coordinates.
  public init (frame: Frame, unit: Unit<Angle>, convention: RotationConvention, x: Double, y: Double, z: Double) {

    let x = radian.convert (x, unit: unit)
    let y = radian.convert (y, unit: unit)
    let z = radian.convert (z, unit: unit)
    
    switch convention {
    case .fixedXYZ:
      self.init (frame: frame,
                 quat: Quaternion.makeAsYawPitchRoll(yaw: z, pitch: y, roll: x))

    case .eulerZYX:
      self.init (frame: frame,
                 quat: Quaternion.makeAsYawPitchRoll(yaw: x, pitch: y, roll: z))
    }
  }

  /// Initialize from three directions, somehow.
  public init? (frame: Frame, unitX: Direction, unitY: Direction, unitZ: Direction) {
    return nil
  }

  /// Initialize form `dir1` and `dir2` as A=dir1, B=dir1xdir2, C=AxB, somehow
  public init? (frame: Frame, dir1: Direction, dir2: Direction) {
    return nil
  }

  /// Initialize an identity orientation in `frame`
  init (frame: Frame) {
    self.init (frame: frame, angle: Quantity<Angle>(value: 0.0, unit: radian), axis: Frame.Axis.z)
  }
}

// MARK: Equatable

extension Orientation : Equatable {
  public static func == (lhs: Orientation, rhs: Orientation) -> Bool {
    return lhs.frame == rhs.frame &&
      lhs.quat == rhs.quat
  }
}

// MARK: Invertable

extension Orientation : Invertable {

  /// The inverse
  public var inverse : Orientation {
    return Orientation (frame: frame, quat: quat.conjugate)
  }
}

// MARK: Rotatable

extension Orientation : Rotatable {
  ///
  ///
  ///
  public func rotate (_ offset: Orientation) -> Orientation {
    let offset = offset.transform (to: frame)
    
    return Orientation (frame: frame,
                        quat: quat.rotate (by: offset.quat))
  }
}

// MARK: Transformable

extension Orientation : Transformable {
  ///
  ///
  ///
  public func transform (to frame: Frame) -> Orientation {
    guard self.frame !== frame else { return self }
    
    // Apply the transformation - inefficiently
    return Frame (orientation: self).transform (to: frame).orientation
  }
  
  ///
  /// Transform `self` by frame to produce a new `framed` that will have a *different* physical
  /// position and orientation.
  ///
  public func transform (by frame: Frame) -> Orientation {
    
    // Put `frame` into our frame
    let that = frame.transform (to: self.frame)
    
    // Apply the transformation - inefficiently
    return Frame (orientation: self).transform (by: that).orientation
  }
  
  
}

// MARK: Composable

extension Orientation : Composable {
  public func compose  (_ offset: Orientation) -> Orientation {
    let offset = offset.transform (to: frame)
    
    return Orientation (frame: frame,
                        quat: offset.quat * self.quat)
  }
}

/*
#if false
extern void frame_orientation_by_fixed_xyz (FrameOrientation o,
                                            SBReal alpha_z,
                                            SBReal beta_y,
                                            SBReal gamma_x)
{
  FrameOrientation x, y, z, yx;
  
  frame_orientation_by_axis_angle (x, SBAxis_X, gamma_x);
  frame_orientation_by_axis_angle (y, SBAxis_Y, beta_y);
  frame_orientation_by_axis_angle (z, SBAxis_Z, alpha_z);
  
  frame_orientation_rotate(yx, y,  x);
  frame_orientation_rotate( o, z, yx);
}

extern void frame_orientation_by_euler_zyx (FrameOrientation o,
                                            SBReal gamma_x,
                                            SBReal beta_y,
                                            SBReal alpha_z)
{ frame_orientation_by_fixed_xyz(o, alpha_z, beta_y, gamma_x); }

//
//
//
extern void frame_orientation_rotate (FrameOrientation tgt,
                                      const FrameOrientation rot,
                                      const FrameOrientation src)
{ matrix_mul ((SBReal *) tgt,
              (SBReal const *) rot,
              (SBReal const *) src,
              3, 3, 3); }

//
//
//
static SBReal mag (SBReal x, SBReal y, SBReal z)
{ return real_sqrt (x*x + y*y + z*z); }

extern void frame_orientation_extract_fixed_xyz_angles (FrameOrientation o,
                                                        SBReal *alpha_z,
                                                        SBReal *beta_y,
                                                        SBReal *gamma_x)
{
  SBReal beta     = real_atan2 ((- o[2][0]), mag (o[0][0], o[1][0], 0));
  SBReal cos_beta = real_cos   (beta);
  
  if (real_pi_2 == beta)
  {
    if (alpha_z) *alpha_z = 0;
    if (beta_y)  *beta_y  = beta;
    if (gamma_x) *gamma_x = real_atan2 (o[0][1], o[1][1]);
  }
  else
  {
    if (alpha_z) *alpha_z = real_atan2 ((o[1][0] / cos_beta), (o[0][0] / cos_beta));
    if (beta_y)  *beta_y  = beta;
    if (gamma_x) *gamma_x = real_atan2 ((o[2][1] / cos_beta), (o[2][2] / cos_beta));
  }
}

extern void frame_orientation_extract_euler_zyx_angles (FrameOrientation o,
                                                        SBReal *gamma_x,
                                                        SBReal *beta_y,
                                                        SBReal *alpha_z)
{ frame_orientation_extract_fixed_xyz_angles(o, alpha_z, beta_y, gamma_x); }

extern void frame_orientation_extract_spherical_angles (FrameOrientation o,
                                                        SBAxis  axis,
                                                        SBReal *phi,
                                                        SBReal *theta)
{ if (phi)   *phi   = real_acos  (o[SBAxis_Z][axis]);
  if (theta) *theta = real_atan2 (o[SBAxis_Y][axis], o[SBAxis_X][axis]); }
 
 
 extern void frame_direction_extract_spherical_angles (const FrameDirection src,
 SBReal *phi,
 SBReal *theta)
 { if (phi)   *phi   = real_acos  (src[SBAxis_Z]);
 if (theta) *theta = real_atan2 (src[SBAxis_Y], src[SBAxis_X]); }

#endif
*/

