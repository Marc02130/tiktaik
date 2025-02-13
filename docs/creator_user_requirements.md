# Creator User Requirements - Week 1 Minimum

## Video Upload Requirements
- Format: MP4, MOV
- Size: Up to 500MB

## Metadata Requirements
### Required Fields
```swift
struct VideoMetadata {
    let id: String
    let title: String              // Required
    let description: String        // Required
    let creatorType: CreatorType   // Required
    let group: String             // Required (genre/subject/cuisine/etc)
    let tags: [String]            // Optional
    let customFields: [String: Any] // Dynamic fields from Firestore
}
```

## Creator Types
1. Chef/Food
2. Fitness
3. Educational
4. Comedy
5. Beauty/Makeup
6. Music

## Basic Features
- Upload video
- Add basic metadata
- Preview before publishing
- Edit metadata after upload

## Common Video Requirements

### Video Upload
- **Video Specifications**
  - Format: MP4, MOV
  - Resolution: Up to 1080p
  - Size: Up to 500MB

## Creator Type Requirements

### 1. Chef/Food Creator
```swift
// Custom fields stored in VideoMetadata.customFields
[
    "ingredients": [String],
    "cookingTime": TimeInterval,
    "cuisineType": String
]
```

### 2. Fitness Creator
```swift
// Custom fields stored in VideoMetadata.customFields
[
    "muscleGroups": [String],
    "equipment": [String],
    "duration": TimeInterval
]
```

### 3. Educational Creator
```swift
// Custom fields stored in VideoMetadata.customFields
[
    "subject": String,
    "level": String,
    "keyPoints": [String]
]
```

### 4. Comedy Creator
```swift
// Custom fields stored in VideoMetadata.customFields
[
    "genre": String,
    "contentRating": String,
    "tags": [String]
]
```

### 5. Beauty/Makeup Creator
```swift
// Custom fields stored in VideoMetadata.customFields
[
    "skillLevel": String,
    "products": [String],
    "techniques": [String]
]
```

### 6. Music Creator
```swift
// Custom fields stored in VideoMetadata.customFields
[
    "genre": String,
    "instruments": [String],
    "isOriginal": Bool
]
```

### Analytics Requirements

#### Viewer Retention Analytics
- Average watch duration per video
- Video completion rate
- Identification of drop-off points
- Most replayed segments
- Viewer retention graph over video duration

#### Engagement Analytics
- Total view count
- Unique viewer count
- Like count and like rate
- Share count and share rate
- Comment count
- Save/bookmark count
- Overall engagement rate
- Trending metrics

#### Geographic Analytics
- Views by country
- Views by city
- Top 10 locations
- Geographic heat map
- Time zone distribution

#### Device Analytics
- Device type distribution (iPhone, iPad)
- OS version distribution
- App version analytics
- Network type usage (WiFi vs Cellular)
- Performance metrics by device

#### Analytics Display Requirements
- Data must be updated at least every 30 minutes
- Interactive graphs and charts
- Exportable reports
- Date range selection
- Comparison with previous periods
- Real-time view counter for new uploads

#### Comment Analytics
- Comment volume metrics
  - Total comments
  - Comments per view ratio
  - Comment frequency over time
  - Peak commenting periods

- Sentiment Analysis
  - Overall sentiment distribution (positive/negative/neutral)
  - Sentiment trends over time
  - Common keywords and phrases
  - Topic clustering

- Engagement Quality
  - Most engaging comments
  - Comment-to-reply ratios
  - Creator response rate
  - Average response time
  - User engagement patterns

- Comment Performance
  - Most liked comments
  - Most replied-to comments
  - Comment timing vs. video timeline
  - Comment retention correlation

- Actionable Insights
  - Content improvement suggestions based on comments
  - Optimal times to respond to comments
  - Controversial content identification
  - Community feedback summaries

- Display Features
  - Sentiment timeline visualization
  - Word clouds for common terms
  - Comment heat maps on video timeline
  - Interactive comment analytics dashboard
