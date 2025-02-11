enum VideoEditingError: Error {
    case trimFailed(String)
    case cropFailed(String)
    case invalidTimeRange
    case invalidCropRect
    case invalidVideo
    case exportFailed(String)
}