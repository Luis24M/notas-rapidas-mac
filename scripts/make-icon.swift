// Dibuja el icono de la app. Uso: swift scripts/make-icon.swift Resources/AppIcon.icns
import AppKit

func render(size: Int) -> Data {
    let scale = CGFloat(size) / 1024
    let context = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.displayP3)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.scaleBy(x: scale, y: scale)
    context.setShouldAntialias(true)

    // Margen y radio de la plantilla de iconos de macOS.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

    context.saveGState()
    context.addPath(tilePath)
    context.clip()
    let background = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.displayP3),
        colors: [
            CGColor(red: 1.00, green: 0.83, blue: 0.25, alpha: 1),
            CGColor(red: 1.00, green: 0.52, blue: 0.10, alpha: 1),
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(background, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

    context.setShadow(offset: CGSize(width: 0, height: -18), blur: 50, color: CGColor(red: 0.55, green: 0.2, blue: 0, alpha: 0.4))
    let sheet = CGRect(x: 250, y: 222, width: 524, height: 580)
    context.addPath(CGPath(roundedRect: sheet, cornerWidth: 72, cornerHeight: 72, transform: nil))
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fillPath()
    context.setShadow(offset: .zero, blur: 0)

    let rowYs: [CGFloat] = [660, 512, 364]
    for (index, y) in rowYs.enumerated() {
        let isDone = index == 0
        let circle = CGRect(x: 318, y: y - 40, width: 80, height: 80)
        if isDone {
            context.setFillColor(CGColor(red: 1.00, green: 0.58, blue: 0.10, alpha: 1))
            context.fillEllipse(in: circle)
            context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.setLineWidth(13)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.move(to: CGPoint(x: 339, y: y - 2))
            context.addLine(to: CGPoint(x: 352, y: y - 15))
            context.addLine(to: CGPoint(x: 378, y: y + 14))
            context.strokePath()
        } else {
            context.setStrokeColor(CGColor(red: 0.80, green: 0.80, blue: 0.82, alpha: 1))
            context.setLineWidth(11)
            context.strokeEllipse(in: circle.insetBy(dx: 5.5, dy: 5.5))
        }
        let line = CGRect(x: 436, y: y - 14, width: 270, height: 28)
        context.addPath(CGPath(roundedRect: line, cornerWidth: 14, cornerHeight: 14, transform: nil))
        context.setFillColor(
            isDone
                ? CGColor(red: 0.86, green: 0.86, blue: 0.88, alpha: 1)
                : CGColor(red: 0.30, green: 0.30, blue: 0.33, alpha: 1)
        )
        context.fillPath()
    }
    context.restoreGState()

    return NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
}

let output = URL(filePath: CommandLine.arguments[1])
let iconset = FileManager.default.temporaryDirectory.appending(path: "AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    try render(size: points).write(to: iconset.appending(path: "icon_\(points)x\(points).png"))
    try render(size: points * 2).write(to: iconset.appending(path: "icon_\(points)x\(points)@2x.png"))
}
let iconutil = Process()
iconutil.executableURL = URL(filePath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try iconutil.run()
iconutil.waitUntilExit()
exit(iconutil.terminationStatus)
