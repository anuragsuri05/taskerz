// Renders the Taskerz app icon into an .iconset folder. Usage: swift make_icon.swift <out.iconset>
import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset")
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    let s = CGFloat(px) / 1024

    // Squircle body following the macOS icon grid (824pt body, 100pt margin).
    let body = CGRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let path = CGPath(roundedRect: body, cornerWidth: 185 * s, cornerHeight: 185 * s, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * s), blur: 28 * s, color: NSColor.black.withAlphaComponent(0.28).cgColor)
    ctx.addPath(path)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let colors = [NSColor(srgbRed: 0.22, green: 0.62, blue: 1.0, alpha: 1).cgColor,
                  NSColor(srgbRed: 0.10, green: 0.36, blue: 0.95, alpha: 1).cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: body.maxY), end: CGPoint(x: 0, y: body.minY), options: [])

    // Soft top highlight.
    let shine = [NSColor.white.withAlphaComponent(0.22).cgColor, NSColor.white.withAlphaComponent(0).cgColor] as CFArray
    let shineGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: shine, locations: [0, 1])!
    ctx.drawLinearGradient(shineGradient, start: CGPoint(x: 0, y: body.maxY), end: CGPoint(x: 0, y: body.midY), options: [])
    ctx.restoreGState()

    // Three rows: a checked circle + line, two open circles + lines.
    let rows: [(y: CGFloat, checked: Bool, length: CGFloat)] = [(650, true, 330), (500, false, 380), (350, false, 260)]
    for row in rows {
        let cx = 330 * s, cy = row.y * s, r = 52 * s
        let circle = CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)
        if row.checked {
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: circle)
            ctx.setStrokeColor(NSColor(srgbRed: 0.12, green: 0.42, blue: 0.97, alpha: 1).cgColor)
            ctx.setLineWidth(17 * s)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.move(to: CGPoint(x: cx - 24 * s, y: cy + 1 * s))
            ctx.addLine(to: CGPoint(x: cx - 6 * s, y: cy - 18 * s))
            ctx.addLine(to: CGPoint(x: cx + 26 * s, y: cy + 20 * s))
            ctx.strokePath()
        } else {
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.92).cgColor)
            ctx.setLineWidth(15 * s)
            ctx.strokeEllipse(in: circle.insetBy(dx: 7.5 * s, dy: 7.5 * s))
        }
        let alpha: CGFloat = row.checked ? 0.6 : 0.95
        ctx.setFillColor(NSColor.white.withAlphaComponent(alpha).cgColor)
        let bar = CGRect(x: 420 * s, y: cy - 19 * s, width: row.length * s, height: 38 * s)
        ctx.addPath(CGPath(roundedRect: bar, cornerWidth: 19 * s, cornerHeight: 19 * s, transform: nil))
        ctx.fillPath()
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    try! render(size).write(to: out.appendingPathComponent("icon_\(size)x\(size).png"))
    try! render(size * 2).write(to: out.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
print("Icon rendered to \(out.path)")
