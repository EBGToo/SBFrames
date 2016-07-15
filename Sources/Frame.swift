//
//  Frame.swift
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

// https://en.wikipedia.org/wiki/Coordinate_system
// https://en.wikipedia.org/wiki/Celestial_coordinate_system
// https://en.wikipedia.org/wiki/List_of_common_coordinate_transformations


// MARK: Framed Protcol

///
/// The `Framed` protocol represents objects that have a Frame - a Frame being a coordinate system
/// defined with a position and orientation.  Examples of types having a frame are: Position,
/// Orientation, Direction and, recursively, a Frame itself.
///
public protocol Framed {
  
  /// The frame
  var frame : Frame { get }
  
  /// The base frame of frame
  var base : Frame { get }
  
  /// The frame that is common to `self` and `that`
  func common (_ that: Self) -> Frame

  /// Check if `frame` is `self`'s frame
  func has (frame : Frame) -> Bool
  
  /// Check if `ancestor` is one of `self`'s ancestor frames
  func has (ancestor: Frame) -> Bool
}

///
///
///
extension Framed {
  
  public var base : Frame {
    // Really just Frame.root
    return self.frame.isBase
      ? self.frame
      : self.frame.base
  }
  
  public func common (_ that: Self) -> Frame {
    return self.has (ancestor: that.frame)
      ? that.frame
      : (that.has (ancestor: self.frame)
        ? self.frame
        : self.base)
  }
  
  public func has (frame : Frame) -> Bool {
    return self.frame === frame
  }
  
  public func has (ancestor: Frame) -> Bool {
    return self.frame === ancestor ||
      (!self.frame.isBase && self.frame.has (ancestor: ancestor))
  }
}

// MARK: Invertable Protocol

///
/// The `Intertable` protocol represents objects that are `Framed` and that are invertable.
/// The single `inverse` computed property produces the inverse.
///
public protocol Invertable : Framed {
  /// Introduces 'self' constraint
  var inverse : Self { get }
}

// MARK: Translatable Protocol

///
/// The 'Translatable' protocol represents objects that are Framed and that are translatable.  
/// Examples include a Position and a Frame.  The protocol defines two methods: `translate` which
/// offsets the translatable; and `translated` which mutates the translatable by the offset.
///
public protocol Translatable : Framed {
  
  ///
  /// Translate `self` by `offset`
  ///
  /// - parameter offset:
  ///
  /// - returns: a new translatable
  ///
  func translate (_ offset: Position) -> Self
  
  ///
  /// Translate `self` by `offset` and then mutate `self`
  ///
  /// - parameter offset:
  ///
  mutating func translated (_ offset: Position)
}

///
///
///
extension Translatable {
  public mutating func translated (_ offset: Position) {
    self = translate (offset)
  }
}

// MARK: Rotatable Protocol

///
/// The `Rotatable` protocol represents objects that are Framed and that are rotatable.  Examples
/// include Position, Orientation, Direction and Frame.  The protocol defines two methods:
/// `rotate` with offsets the rotatable; and `rotated` which mutates the rotatable by the offset.
///
public protocol Rotatable : Framed {
  
  ///
  /// Rotate `self` by `offset`
  ///
  /// - parameter offset:
  ///
  /// - returns: a new rotatable
  ///
  func rotate (_ offset: Orientation) -> Self
  
  ///
  /// Rotate `self` by `offset` and then mutate `self`
  ///
  /// - parameter offset:
  ///
  mutating func rotated (_ offset: Orientation)
}

extension Rotatable {
  public mutating func rotated (_ offset: Orientation) {
    self = rotate (offset)
  }
}

// MARK: Transformable Protocol

///
/// The `Transformable` protocol represents objects that are Framed adn that are transformable.
/// Examples include Position, Orientation, Direction and Frame.  The protocol defines three
/// methods: `transform:by` with returns a new transformable transformed by frame; `transform:to`
/// which returns a new transformable transformed to frame (it represents the same physical
/// position and orientation); and `transformed`
///
public protocol Transformable : Framed {

  ///
  /// Transform 'self' to frame.  Once transformed `self` will represent the *same* physical
  /// position and orientation; it will just be represented in the provided frame.
  ///
  /// - parameter to:
  ///
  /// - returns: 
  ///
  func transform (to frame: Frame) -> Self
  
  ///
  /// Transform `self` to `frame` as if by `transform:to` and then mutate `self`
  ///
  /// - parameter to:
  ///
  mutating func transformed (to frame: Frame)
  
  ///
  /// Transform `self` by frame to produce a new `framed` that will have a *different* physical
  /// position and orientation.
  ///
  /// - parameter to:
  ///
  /// - returns
  ///
  func transform (by frame: Frame) -> Self
  
  ///
  /// Transform `self` to `frame` as if by `transform:by` and then mutate `self`
  ///
  /// - parameter to:
  ///
  mutating func transformed (by frame: Frame)
}

///
///
///
extension Transformable {
  public mutating func transformed (to frame: Frame) {
    self = transform(to: frame)
  }
  
  public mutating func transformed (by frame: Frame) {
    self = transform(by: frame)
  }

}

// MARK: Composable Protocol

///
/// The `composable` protocol represents objects that are Framed and that are composable.
///
public protocol Composable : Framed {
  
  ///
  /// Compose `self` with `offset`
  ///
  /// - parameter offset:
  ///
  /// - returns:
  ///
  func compose  (_ offset: Self) -> Self
}

// ==============================================================================================
//
// MARK: Frame
//
//

/// A Frame represents a 3d spatial position and orientation in a cartesian coordinate system.  One
/// frame is designated as the 'base frame'.  Other frames are formed by a translation (by position)
/// and a rotation (by orientation) from a 'parent' frame.  Frames are built upon frames, ultimately
/// recursing back down to the 'base frame'.  [Note: even the 'base frame' has a parent (itself), a
/// position (zero) and an orientation (identity) - this is an implementation convenience to avoid
/// Optional types for `frame`, `position` and `orientation` properties].
///
/// Importantly a `Frame` is a reference type and is mutable, in some limited ways.  The
/// mutability implies that if frame X changes to a different physical location, then all child
/// frames will change physical location too.  For example, a spacecraft has a camera attached to 
/// the spacecraft (mechanical) bus; the camera's lens has a defined boresight.  When the 
/// spacecraft rotates, the boresight (a direction in the camera's frame) changes too - even
/// though neither the direction in camera frame nor the camera frame in the spacecraft frame
/// changed.
///
/// Consider the implication of a Frame implemented as a value type.  All direct children would 
/// point to the same parent but then, if the parent is mutated, all the direct children would
/// point to the original parent.  For the mutated parent to impact the children, every child,
/// themselves value types, would need to be 'reallocated', and so on down the tree.  Any object
/// holding a frame anywhere at or below the mutated parent would hold the original.  It is not
/// a pleasant thought (see SBBasics::Tree for a value type binary tree) to handle updating all 
/// subtree references.
///
/// When implemented as a reference type, referencers will need to 'register' (in a TBD manner) to
/// learn of frame changes.  One expects this to be common - not only does a camera need to know
/// when it's boresight has changed, it also needs to know when an asteroid has moved (and would be
/// registering for the asteriod's frame changes too).
///
public final class Frame : Framed  {
  
  /// The 'parent' frame
  public internal(set) lazy var frame : Frame = {
    [unowned self] in
    return self
  }()

  /// The unit.  Derived from the frame's position and `meter` by default.
  public internal(set) var unit : Unit<Length> = meter
  
  /// The dual, a DualQuaternion
  internal var dual : DualQuaternion = DualQuaternion.identity
  
  /// The position in `frame`
  var position : Position {
    return Position (frame: frame, unit: unit, quat: dual.asTranslation)
  }
  
  /// The orientation in `frame`
  var orientation : Orientation {
    return Orientation (frame: frame, quat: dual.asRotation)
  }

  /// Return `true` iff `self` is `base`
  var isBase : Bool {
    return frame === self
  }
  
  // MARK: Position and Orientation Factory
  
  ///
  ///
  ///
  func translation (unit: Unit<Length>, x: Double, y: Double, z: Double) -> Position {
    return Position (frame: self, unit: unit, x: x, y: y, z: z)
  }
  
  ///
  ///
  ///
  func rotation (angle: Quantity<Angle>, direction: Direction) -> Orientation {
      return Orientation (frame: self, angle: angle, direction: direction)
  }

  // MARK: Update
  internal func updated (to target: Frame) {
    self.frame = target.frame
    self.unit  = target.unit
    self.dual  = target.dual
  }
  
  // MARK: Initialize

  /// The one and only one base frame, privately.
  private init () {}

  ///
  /// Initialize with a DualQuaternion
  ///
  /// - parameter frame:
  /// - parameter unit:
  /// - parameter dual:
  ///
  internal init (frame: Frame, unit: Unit<Length>, dual: DualQuaternion) {
    self.frame = frame
    self.unit = unit
    self.dual = dual
  }

  ///
  /// Initialize with a Position
  ///
  /// - parameter position:
  ///
  public convenience init (position : Position) {
    self.init (frame: position.frame,
               unit: position.unit,
               dual: DualQuaternion (translation: position.quat))
  }
  
  ///
  /// Initialize with an Orientation
  ///
  /// - parameter orientation:
  ///
  public convenience init (orientation : Orientation) {
    self.init (frame: orientation.frame,
               unit: meter,
               dual: DualQuaternion (rotation: orientation.quat))
  }
  
  ///
  /// Initialize with a Position and an Orientation; use the position's frame as the 'parent'
  ///
  /// - parameter position:
  /// - parameter orientation:
  ///
  public convenience init (position : Position, orientation : Orientation) {
    self.init (frame: position.frame,
               position: position,
               orientation: orientation)
  }
  
  ///
  /// Initialize with a Position and an Orientation in the provided Frame.  Both position and
  /// orientation are converted to frame, if they are not currently in frame.
  ///
  /// - parameter frame:
  /// - parameter position:
  /// - parameter orientation:
  ///
  public convenience init (frame: Frame, position : Position, orientation : Orientation) {
    // self.position = position.transform (to: frame)
    // self.orientation = orientation.transform(to: frame)
    self.init (frame: frame,
               unit: position.unit,
               dual: DualQuaternion (rotation: orientation.transform(to: frame).quat,
                                     translation: position.transform(to: frame).quat))
  }

  // MARK: Root Frame
  
  ///
  /// The `root` frame is the base for all frames.  There is one and only one base frame; you'll
  /// define the semantics of this frame and, importantly, you never need to descend to this depth
  /// if you instead define all our frames under one other frame (which will be a subframe of
  /// base).
  ///
  public static let root = Frame()

  // MARK: Axis
  
  ///
  /// An Axis enum represents X, Y and Z axes.
  ///
  public enum Axis : Int, CustomStringConvertible {
    case x = 0
    case y = 1
    case z = 2
    
    static var names = ["x", "y", "z"]
    
    var name : String { return Axis.names[self.rawValue] }
    
    public var description : String { return name }
  }
}

// MARK: Equatable

extension Frame : Equatable {
  public static func == (lhs: Frame, rhs: Frame) -> Bool {
    return lhs === rhs
  }
}

// MARK: Invertable

extension Frame : Invertable {
  ///
  ///
  ///
  public var inverse : Frame {
    return Frame (frame: frame,
                  unit: unit,
                  dual: dual.inverse)
  }
}

// MARK: Rotatable

extension Frame : Rotatable {

  /// Rotate `self` returning a new `Frame`
  ///
  /// - argument offset: the orientation to rotate by
  ///
  /// - returns: `self` rotated
  ///
  public func rotate (_ offset: Orientation) -> Frame {
    return transform(by: Frame (orientation: offset))
  }

  /// Rotate `self` and then mutate `self`.  Note: overrides the Protocol extension to ensure that
  /// `self` is in fact mutated.
  ///
  /// - argument offset: the orientation to rotate by
  ///
  public func rotated(_ offset: Orientation) {
    transformed (by: Frame (orientation: offset))
  }
}

// MARK: Translatable

extension Frame : Translatable {

  /// Translate `self` returning a new `Frame`
  ///
  /// - argument offset: the position to translate by
  ///
  /// - returns: `self` translated
  ///
  public func translate (_ offset: Position) -> Frame {
    return transform(by: Frame (position: offset))
  }

  /// Translate `self` and then mutate `self`.  Note: overrides the Protocol extension to ensure 
  /// that `self` is in fact mutated.
  ///
  /// - argument offset: the position to translate by
  ///
  public func translated (_ offset: Position) {
    transformed (by: Frame (position: offset))
  }
}

// MARK: Transformable

extension Frame : Transformable {
  public func transformed (to frame: Frame) {
    updated (to: transform (to: frame))
  }

  public func transformed (by frame: Frame) {
    updated (to: transform (by: frame))
  }

  ///
  ///
  ///
  public func transform (to that: Frame) -> Frame {
    let parent = self.frame
    
    //    guard self !== Frame.root else {
    //      preconditionFailure("transform root")
    //    }
    
    // `that` is `self`'s parent - done, return `self`
    if parent === that {
      return Frame (frame: self.frame, unit: self.unit, dual:  self.dual)
    }
      
    // `frame` is the parent of `self.frame` - convert to `parent`
    else if parent.has (frame: that) {
      return Frame (frame: that,
                    unit: that.unit,
                    dual: parent.dual * self.dual)
    }
      
    // `frame` is an ancestor (beyond parent) of `self.
    else if parent.has (ancestor: that) {
      return self.transform (to: parent.frame)
        .transform (to: that)
    }
      
    // `self is the parent of `frame`
    else if that.has (frame: self) {
      return Frame (frame: that,
                    unit: that.unit,
                    dual: that.dual.inverse)
    }
      
    // `self` is an ancestor (beyond parent) of `frame`
    else if that.has (ancestor: self) {
      let x = that.transform (to: self)
      return Frame (frame: that,
                    unit: that.unit,
                    dual: x.dual.inverse)
    }

      // `self` up to `common`, then  down to `that`
    else {
      let common = self.common (that)
      
      let self_to_common = self.transform (to: common)
      let common_to_that = common.transform (to: that)
      
      return Frame (frame: that,
                    unit: that.unit,
                    dual:  common_to_that.dual * self_to_common.dual)
    }
  }
  
  ///
  /// Transform `self` by `frame` to produce a new framed that will have a *different* physical
  /// position and orientation.  The result will be in `self.frame`.
  ///
  public func transform (by frame: Frame) -> Frame {
    
    // Transform that into self's frame
    let that = frame.transform (to: self.frame)
    
    return Frame (frame: self.frame,
                  unit: self.unit,
                  dual: that.dual * self.dual)
  }

}

// MARK: Composable

extension Frame : Composable {
  public func compose(_ offset: Frame) -> Frame {
    let that = offset.transform(to: frame)
    return Frame (frame: frame,
                  unit: unit,
                  dual: that.dual * self.dual)
  }
}

// NOTE: The position and orientation of a FRAME needs to be writeable.  For
// example, a Spacecraft has a frame which defines the coordinate system for
// all spacecraft devices.  Each device will define their own coordinate system
// with a parent given by the spacecraft's frame.  When the spacecraft moves,
// the physical coordinate system of the spacecraft changes.  If an SBFrame
// is immutable then the spacecraft's frame could be changed but then all the
// attached devices would a) still reference the old frame or b) all need to be
// updated to the changed frame - that at least if one needed to transform from
// the device to coordiates 'above' the spacecraft (like planets, stars, etc).
// As it stands a frame does not maintain an association with its children and
// thus option 'b' - updating all referencing frames with the next frame - is
// practically impossible.  The other option is to make SBFrame properties for
// POSITION and ORIENTATION writeable.
//
// If a FRAME's POSITION and ORIENTATION are writeable then changes would need
// to be monitorable.  Thus, for example, a star tracker could compute the ever
// changing direction of the sun so as to avoid staring into the light.  And, of
// course, on change, any cached FrameTransform data would need to be flushed.
//


// Type: Rectangular, Spherical, Cylindrical, etc.
//   => Created POSITION, ORIENTATION off of FRAME must be of the correct type.


// MORE DISCUSSION

// Every frame has a position and an orientation - for the 'base frame' they are 'zero'
//   No, the position itself has a 'frame' even if zero.  If user accesses that frame, then the
//   user now has a frame w/o a position.
//
// Base frame has no parent, no position, no orientation.  THERE IS NO OTHER POSSIBILITY
//   (at least if position, orientation will have a frame)
//
// What is the coordindate system for a base frame: rectangular, spherical, cylindrical?


// ============================================================================================== //
//
// Imagine:
//   a well-defined base frame
//   a sun expressed in the base-frame
//   a moving spacecraft in the base-frame
//   a camera on the spacecraft with a frame relative to the spacecraft's and a view direction
//     (assume the camera and/or the camera's frame listens to spacecraft motion and will close
//      a shutter if the camera's view 'hits' the sun)
//
// The spacecraft moves:
//   The sun itself didn't move, but the postion/orientation relative to the spacecraft did.
//   The camera moved - it is attached to the spacecraft
//     The angle between the camera's direction and the sun changed.
//
// Key Question // Design Issue
//
//  Q-1-A: Is the frame of the spacecraft modified (spacecraft reference to the frame is unchanged
//    but the frame's position and orientation changed)
//
//  Q-1-B: Is the spacecraft's frame changed (perhaps a frame is immutable (value semantics); the
//    spacecraft has a newly allocated frame)
//  Analysis: the camera registered with the spacecraft; the camera knows it is mounted on the
//    spacecraft with a fixed (parameterized) position/orientation offet.  The camera, like the
//    spacecraft has it's own frame.  On callback, the camera frame is changed as:
//      cFrame2 = Frame(scFrame2, Postion(scFrame2, fixedOffset), Orientation(scFrame2, fixedOffset)
//        where fixedOffset are the 'hard numbers' relative to the original scFrame1
//    On callback, the view direcion is updated
//    With new direction, the angle between view and sun is measured; shutter is closed if needed.
//
//  Q-2: The spacecraft has a 'reference frame' with reference semantics; a 'coordinate system'
//     has value semantics?

//  Q-3: A Position is 'Framed'; a Spacecraft is 'Framed' - that does not seem correct as they are
//    vastly different conceptually.  Position vs Point?  Point expressed with different positions
//    depending on coordinate system.  Point moves -> all positions changed.
//      Point -> Position
//      Line -> Direction
//      Body -> Frame (position + orientation)
//
//  Q-4: Race Condition: Two objects a camera and a thruster on the spacecraft; camera is
//    interested in thruster plume.  Spacecraft moves (position+orientation); camera and thruster
//    are updated (somehow, see Q-1), camera computes plume impact.
//  Answer-ish: If reference semantics, when spacecraft moves, both camera and thruster
//    'instantaneously' have different positions/orientations (relative to some third frame). If
//    value semantics, camera and thruster frames need to be updated and only then computed.
//
//  Q-5: Sun moves.  Spacecraft registered as 'interested'; updates computed properties.  Does the
//    Sun notify (should be) or does the Sun's frame notify the S/C frame (can't be)?
//
//  Q-6: Updating Race Condition - A Frame is having it's Postion + Orientation updated, any
//    subframe may perform a computation using its 'half updated' parent...  Unless updates are
//    atomic.
//
//    Frame notifies listeners of its replacement?  Listeners assign the replacement as the new
//    parent?  [Listeners need to be sure they are not between computations using the parent -
//    which gets changed during the computations.]
//
//    New frame allocated as (parent: new, position: old, orientation: old) - no, old position and
//    orientation will point to old frame.
//
//


