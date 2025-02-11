import CoreGraphics

extension CGRect {
    /// Returns a normalized version of the rect where width and height are positive
    var normalized: CGRect {
        var rect = self
        if rect.size.width < 0 {
            rect.origin.x += rect.size.width
            rect.size.width = abs(rect.size.width)
        }
        if rect.size.height < 0 {
            rect.origin.y += rect.size.height
            rect.size.height = abs(rect.size.height)
        }
        return rect
    }
} 