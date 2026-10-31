#!/usr/bin/env swift
// Erzeugt die App-Icon-Varianten fuer HealthWake.
// Regeln: volle quadratische Flaeche, keine runden Ecken, kein gebackenes
// Glanzlicht und kein Schlagschatten -- die Maske und das Licht gehoeren dem
// System. Ein Brennpunkt, kein Text, bei 60 px noch lesbar.

import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let S: CGFloat = 1024

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

func opaqueContext() -> CGContext {
    CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8,
              bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
}

func alphaContext() -> CGContext {
    CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8,
              bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func writePNG(_ image: CGImage, _ path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)
    else { fatalError("Ziel \(path) nicht beschreibbar") }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

func gradient(_ ctx: CGContext, _ from: CGColor, _ to: CGColor) {
    let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                       colors: [from, to] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0),
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

/// Herzschlag-Zug. Schmaler als die Kante, damit Rand bleibt.
func pulsePath(width: CGFloat, baseline: CGFloat = 0.455, peak: CGFloat = 0.715,
               dip: CGFloat = 0.315, from: CGFloat = 0.175, to: CGFloat = 0.735) -> CGPath {
    let pts: [(CGFloat, CGFloat)] = [
        (from, baseline), (0.335, baseline), (0.405, dip),
        (0.500, peak), (0.580, baseline), (to, baseline)
    ]
    let p = CGMutablePath()
    p.move(to: CGPoint(x: pts[0].0 * S, y: pts[0].1 * S))
    for pt in pts.dropFirst() { p.addLine(to: CGPoint(x: pt.0 * S, y: pt.1 * S)) }
    return p.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 10)
}

func heartPath() -> CGPath {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: S * 0.500, y: S * 0.225))
    p.addCurve(to: CGPoint(x: S * 0.165, y: S * 0.620),
               control1: CGPoint(x: S * 0.320, y: S * 0.375),
               control2: CGPoint(x: S * 0.165, y: S * 0.465))
    p.addCurve(to: CGPoint(x: S * 0.500, y: S * 0.620),
               control1: CGPoint(x: S * 0.165, y: S * 0.840),
               control2: CGPoint(x: S * 0.405, y: S * 0.850))
    p.addCurve(to: CGPoint(x: S * 0.835, y: S * 0.620),
               control1: CGPoint(x: S * 0.595, y: S * 0.850),
               control2: CGPoint(x: S * 0.835, y: S * 0.840))
    p.addCurve(to: CGPoint(x: S * 0.500, y: S * 0.225),
               control1: CGPoint(x: S * 0.835, y: S * 0.465),
               control2: CGPoint(x: S * 0.680, y: S * 0.375))
    p.closeSubpath()
    return p
}

// Die gewaehlte Richtung: der Herzschlagzug endet in einem Punkt -- der
// neue Wert, der eintrifft.
//
// Drei Erscheinungsbilder, wie iOS 18 sie erwartet:
//   hell    Standard
//   dunkel  gedaempfter Hintergrund fuer dunkle Home-Screens
//   getoent STRENG graustufig; iOS legt die Toenung des Nutzers darueber.
//           Jede gebackene Farbe wuerde hier falsch rendern.
struct Appearance {
    let name: String
    let bg0: UInt32, bg1: UInt32, mark: UInt32, dot: UInt32
}

let appearances = [
    Appearance(name: "icon_light",  bg0: 0x0B2B45, bg1: 0x12806F, mark: 0xFFFFFF, dot: 0x7CF0C8),
    Appearance(name: "icon_dark",   bg0: 0x05141F, bg1: 0x0A3F3A, mark: 0xF2F7F6, dot: 0x4FBF9F),
    Appearance(name: "icon_tinted", bg0: 0x141414, bg1: 0x3A3A3A, mark: 0xFFFFFF, dot: 0xA8A8A8)
]

func render(_ a: Appearance) -> CGImage {
    let ctx = opaqueContext()
    gradient(ctx, rgb(a.bg0), rgb(a.bg1))
    ctx.setFillColor(rgb(a.mark))
    ctx.addPath(pulsePath(width: S * 0.082))
    ctx.fillPath()
    let r = S * 0.072
    ctx.setFillColor(rgb(a.dot))
    ctx.fillEllipse(in: CGRect(x: S * 0.815 - r, y: S * 0.455 - r, width: 2 * r, height: 2 * r))
    return ctx.makeImage()!
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
for a in appearances {
    writePNG(render(a), "\(out)/\(a.name).png")
    print("geschrieben: \(a.name).png")
}
