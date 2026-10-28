// Renders the DMG window background (1x and 2x). Usage: swift make_dmg_background.swift <out-dir>
import AppKit

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let size = CGSize(width: 660, height: 400)

func render(scale: CGFloat) -> Data {
    let px = Int(size.width * scale), py = Int(size.height * scale)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: py, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext

    // Soft light gradient.
    let colors = [NSColor(srgbRed: 0.98, green: 0.98, blue: 0.99, alpha: 1).cgColor,
                  NSColor(srgbRed: 0.92, green: 0.94, blue: 0.97, alpha: 1).cgColor] as CFArray
    let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: size.height), end: .zero, options: [])

    // Arrow between the app (x=170) and Applications (x=490) icons, centered at y=190 from top.
    let y = size.height - 190
    let arrow = NSBezierPath()
    arrow.lineWidth = 3
    arrow.lineCapStyle = .round
    arrow.move(to: CGPoint(x: 262, y: y))
    arrow.line(to: CGPoint(x: 392, y: y))
    arrow.move(to: CGPoint(x: 378, y: y + 12))
    arrow.line(to: CGPoint(x: 394, y: y))
    arrow.line(to: CGPoint(x: 378, y: y - 12))
    NSColor(srgbRed: 0.55, green: 0.58, blue: 0.64, alpha: 1).setStroke()
    arrow.stroke()

    func draw(_ text: String, y: CGFloat, font: NSFont, color: NSColor) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: style]
        NSString(string: text).draw(in: CGRect(x: 0, y: y, width: size.width, height: 30), withAttributes: attrs)
    }
    draw("Drag Taskerz to Applications to install", y: 62,
         font: .systemFont(ofSize: 15, weight: .semibold), color: NSColor(white: 0.2, alpha: 1))
    draw("Works on Apple silicon and Intel Macs · macOS 14 or later", y: 38,
         font: .systemFont(ofSize: 11.5), color: NSColor(white: 0.45, alpha: 1))

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

try! render(scale: 1).write(to: outDir.appendingPathComponent("background.png"))
try! render(scale: 2).write(to: outDir.appendingPathComponent("background@2x.png"))
print("DMG background rendered")
