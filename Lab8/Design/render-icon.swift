import AppKit
import UniformTypeIdentifiers
import WebKit

let args = CommandLine.arguments
let svg = try! String(contentsOfFile: args[1], encoding: .utf8)
let output = URL(fileURLWithPath: args[2])
let size = args.count > 3 ? Int(args[3])! : 1024
let transparent = args.count > 4 && args[4] == "transparent"
let canvas = 1024

final class Renderer: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let config = WKSnapshotConfiguration()
        config.rect = CGRect(x: 0, y: 0, width: canvas, height: canvas)
        config.snapshotWidth = NSNumber(value: canvas)
        webView.takeSnapshot(with: config) { image, error in
            guard let source = image?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                fatalError(error?.localizedDescription ?? "snapshot failed")
            }
            let alpha = transparent ? CGImageAlphaInfo.premultipliedLast : .noneSkipLast
            let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                    bitmapInfo: alpha.rawValue)!
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            if !transparent {
                context.setFillColor(.white)
                context.fill(rect)
            }
            context.interpolationQuality = .high
            context.draw(source, in: rect)
            let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
            CGImageDestinationAddImage(destination, context.makeImage()!, nil)
            CGImageDestinationFinalize(destination)
            exit(0)
        }
    }
}

let app = NSApplication.shared
let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: canvas, height: canvas))
if transparent { webView.setValue(false, forKey: "drawsBackground") }
let renderer = Renderer()
webView.navigationDelegate = renderer
webView.loadHTMLString("<html><body style=\"margin:0;overflow:hidden;background:transparent\">\(svg)</body></html>", baseURL: nil)
app.run()
