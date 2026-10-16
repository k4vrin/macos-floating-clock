import AppKit

struct BarGeometry: Equatable {
    let screenFrame: NSRect
    let center: CGFloat
    let gap: CGFloat
    let height: CGFloat

    var compactWidth: CGFloat { gap + 224 }

    func frame(expanded: Bool) -> NSRect {
        let desiredWidth = expanded ? max(640, compactWidth) : compactWidth
        let width = min(desiredWidth, 2 * min(center - screenFrame.minX, screenFrame.maxX - center))
        let totalHeight = height + (expanded ? 390 : 0)
        return NSRect(x: center - width / 2, y: screenFrame.maxY - totalHeight,
                      width: width, height: totalHeight)
    }
}

/// Captured in screen coordinates and points, including displays above or left of the primary display.
struct MenuBarMetrics {
    let frame: NSRect
    let visibleFrame: NSRect
    let scale: CGFloat
    let safeTop: CGFloat
    let leftArea: NSRect?
    let rightArea: NSRect?
    var statusItemHeight: CGFloat? = nil
    var fallbackHeight: CGFloat

    func resolve(previousHeight: CGFloat? = nil) -> BarGeometry? {
        guard scale > 0, frame.width > 0, frame.height > 0 else { return nil }
        var center = frame.midX
        var gap: CGFloat = 0
        if safeTop > 0 {
            // Without both native auxiliary areas we cannot safely locate the cutout.
            guard let leftArea, let rightArea, !leftArea.isEmpty, !rightArea.isEmpty,
                  frame.contains(leftArea), frame.contains(rightArea),
                  leftArea.maxX <= rightArea.minX else { return nil }
            center = (leftArea.maxX + rightArea.minX) / 2
            gap = rightArea.minX - leftArea.maxX
        }
        let reserved = max(0, frame.maxY - visibleFrame.maxY)
        // Auto-hide may leave only a one-pixel reveal strip. Preserve the last measured
        // band for this display configuration instead of shrinking the controls to it.
        let measured = reserved > 1 / scale && reserved < frame.height ? reserved : nil
        let nativeNotchHeight: CGFloat? = safeTop > 0 ? safeTop : nil
        let candidate = measured ?? previousHeight ?? nativeNotchHeight ?? statusItemHeight ?? fallbackHeight
        let limit = safeTop > 0 ? min(candidate, safeTop) : candidate
        let height = floor(min(limit, frame.height) * scale) / scale
        guard height > 0, height.isFinite else { return nil }
        return BarGeometry(screenFrame: frame, center: center, gap: gap, height: height)
    }
}

@MainActor
final class MenuBarGeometryResolver {
    private struct Measurement {
        let frame: NSRect
        let scale: CGFloat
        let height: CGFloat
    }
    private var measurements: [CGDirectDisplayID: Measurement] = [:]

    func geometry(for screen: NSScreen, statusWindow: NSWindow?) -> BarGeometry? {
        let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
        let previous = measurements[displayID]
        let cachedHeight = previous.flatMap {
            $0.frame == screen.frame && $0.scale == screen.backingScaleFactor ? $0.height : nil
        }
        var itemHeight: CGFloat?
        if let statusWindow, statusWindow.screen == screen,
           abs(statusWindow.frame.maxY - screen.frame.maxY) <= 1 / screen.backingScaleFactor {
            itemHeight = statusWindow.frame.height
        }
        let metrics = MenuBarMetrics(frame: screen.frame, visibleFrame: screen.visibleFrame,
            scale: screen.backingScaleFactor, safeTop: screen.safeAreaInsets.top,
            leftArea: screen.auxiliaryTopLeftArea, rightArea: screen.auxiliaryTopRightArea,
            statusItemHeight: itemHeight, fallbackHeight: NSStatusBar.system.thickness)
        let result = metrics.resolve(previousHeight: cachedHeight)
        // Only cache an actual reservation, never a global fallback from a hidden bar.
        if let result, screen.frame.maxY - screen.visibleFrame.maxY > 1 / screen.backingScaleFactor {
            measurements[displayID] = Measurement(frame: screen.frame, scale: screen.backingScaleFactor,
                                                   height: result.height)
        }
        return result
    }
}
