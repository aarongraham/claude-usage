import AppKit
import CoreGraphics

// Renders the ClaudeUsage app icon as Resources/AppIcon.icns.
// Run from repo root: `swift Tools/generate_icon.swift`

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // Background: rounded square with vertical gradient (off-peak blue → peak warm).
    let inset = size * 0.06
    let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let cornerRadius = size * 0.225
    let bgPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let topColor = CGColor(srgbRed: 0.13, green: 0.32, blue: 0.52, alpha: 1.0)
    let bottomColor = CGColor(srgbRed: 0.07, green: 0.18, blue: 0.32, alpha: 1.0)
    let gradient = CGGradient(colorsSpace: colorSpace,
                              colors: [topColor, bottomColor] as CFArray,
                              locations: [0.0, 1.0])!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: 0, y: 0),
                           options: [])
    ctx.restoreGState()

    // Subtle inner highlight at top.
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    let highlight = CGGradient(colorsSpace: colorSpace,
                               colors: [CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.10),
                                        CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0)] as CFArray,
                               locations: [0.0, 0.6])!
    ctx.drawLinearGradient(highlight,
                           start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: 0, y: size * 0.4),
                           options: [])
    ctx.restoreGState()

    // Hexagon glyph.
    let center = CGPoint(x: size / 2, y: size / 2)
    let radius = size * 0.30
    let strokeWidth = max(1, size * 0.05)

    func hexagonPath(radius r: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for i in 0..<6 {
            // pointy-top hexagon — angle 90, 150, 210, 270, 330, 30
            let angle = CGFloat.pi / 2 + CGFloat(i) * (.pi / 3)
            let x = center.x + r * cos(angle)
            let y = center.y + r * sin(angle)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }

    // Inner filled hexagon representing "usage filled" — about 65% area, warm accent.
    let innerRadius = radius * 0.78
    ctx.saveGState()
    ctx.addPath(hexagonPath(radius: innerRadius))
    ctx.clip()
    let fillGradient = CGGradient(colorsSpace: colorSpace,
                                  colors: [CGColor(srgbRed: 0.95, green: 0.74, blue: 0.50, alpha: 0.95),
                                           CGColor(srgbRed: 0.78, green: 0.55, blue: 0.36, alpha: 0.95)] as CFArray,
                                  locations: [0.0, 1.0])!
    ctx.drawLinearGradient(fillGradient,
                           start: CGPoint(x: 0, y: center.y + innerRadius),
                           end: CGPoint(x: 0, y: center.y - innerRadius),
                           options: [])
    ctx.restoreGState()

    // Outer hexagon ring — white stroke.
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.95))
    ctx.setLineWidth(strokeWidth)
    ctx.setLineJoin(.round)
    ctx.addPath(hexagonPath(radius: radius))
    ctx.strokePath()
    ctx.restoreGState()

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "icon", code: 1)
    }
    try data.write(to: url)
}

let fm = FileManager.default
let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
let iconsetURL = cwd.appendingPathComponent("Tools/AppIcon.iconset")
try? fm.removeItem(at: iconsetURL)
try fm.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let sizes: [(name: String, size: CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for entry in sizes {
    let img = drawIcon(size: entry.size)
    let outURL = iconsetURL.appendingPathComponent(entry.name)
    try savePNG(img, to: outURL)
    print("wrote \(entry.name)")
}

print("done")
