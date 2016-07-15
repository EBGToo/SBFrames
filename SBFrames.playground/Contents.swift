//: Playground - noun: a place where people can play

import SBUnits
import SBFrames

var base = Frame.root

var p1 = Position(frame: Frame.root)
p1.x
p1.y
p1.z


var o1 = Orientation(frame: Frame.root, angle: Quantity<Angle>(value: 45.0, unit: degree), axis: .x)

var f1 = Frame (frame: base, position: p1, orientation: o1)

f1.has(frame: Frame.root)
f1.has(ancestor: Frame.root)
