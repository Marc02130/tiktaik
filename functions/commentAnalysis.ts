import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import OpenAI from 'openai';

interface Comment {
    id: string;
    videoId: string;
    content: string;
    likesCount: number;
}

interface AnalysisResult {
    sentiment: number;
    topics: { [key: string]: number };
}

export const processComments = onSchedule({
    schedule: 'every 10 minutes',
    secrets: ["OPENAI_API_KEY"]
}, handler);

// Extract the handler function
export async function handler() {
    const db = admin.firestore();
    const openai = new OpenAI({
        apiKey: process.env.OPENAI_API_KEY
    });
    
    console.log("Starting comment analysis...");
    
    // Get all comments without 'analyzed' field
    const untaggedSnapshot = await db.collection('videoComments')
        .orderBy('analyzed')
        .startAt(null)
        .endAt(null)
        .limit(100)
        .get();

    // Add 'analyzed: false' to all untagged comments
    if (!untaggedSnapshot.empty) {
        const batch = db.batch();
        untaggedSnapshot.docs.forEach(doc => {
            batch.update(doc.ref, { analyzed: false });
        });
        await batch.commit();
        console.log(`Added 'analyzed' field to ${untaggedSnapshot.size} comments`);
    }

    // Now get unanalyzed comments
    let snapshot = await db.collection('videoComments')
        .where('analyzed', '==', false)
        .limit(100)
        .get();

    // If no unanalyzed comments found, check for comments without 'analyzed' field
    if (snapshot.empty) {
        // Try to get comments where 'analyzed' field doesn't exist
        const untaggedSnapshot = await db.collection('videoComments')
            .orderBy('analyzed')
            .startAt(null)
            .endAt(null)
            .limit(100)
            .get();
        
        if (untaggedSnapshot.empty) {
            console.log('No unanalyzed comments found');
            return;
        }
        
        console.log(`Found ${untaggedSnapshot.size} comments without 'analyzed' field`);
        console.log("Comments to analyze:", untaggedSnapshot.docs.map(doc => ({
            id: doc.id,
            content: doc.data().content,
            analyzed: doc.data().analyzed
        })));
        
        // Use these comments instead
        snapshot = untaggedSnapshot;
    }

    console.log(`Found ${snapshot.size} unanalyzed comments`);
    console.log("Comments to analyze:", snapshot.docs.map(doc => ({
        id: doc.id,
        content: doc.data().content,
        analyzed: doc.data().analyzed
    })));

    const comments = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
    })) as Comment[];

    // Group comments by video
    const commentsByVideo = comments.reduce<{ [key: string]: Comment[] }>((acc, comment) => {
        if (!acc[comment.videoId]) {
            acc[comment.videoId] = [];
        }
        acc[comment.videoId].push(comment);
        return acc;
    }, {});

    console.log(`Grouped comments for ${Object.keys(commentsByVideo).length} videos`);

    // Process each video's comments
    for (const [videoId, comments] of Object.entries(commentsByVideo)) {
        try {
            console.log(`Processing ${comments.length} comments for video ${videoId}`);
            
            // Get total comment count for this video
            const totalComments = await db.collection('videoComments')
                .where('videoId', '==', videoId)
                .count()
                .get();
            
            // Analyze comments with OpenAI
            const analysis = await analyzeComments(comments, openai);
            console.log('Analysis result:', analysis);
            
            // Update video analytics
            const analyticsData = {
                videoId,
                lastProcessedAt: admin.firestore.FieldValue.serverTimestamp(),
                commentCount: totalComments.data().count,
                batchStatus: 'completed',
                metrics: {
                    sentiment: analysis.sentiment,
                    topics: analysis.topics,
                    engagement: calculateEngagement(comments),
                    processedCount: comments.length
                }
            };
            
            console.log('Updating analytics with:', analyticsData);
            
            await db.collection('videoAnalytics')
                .doc(videoId)
                .set(analyticsData, { merge: true });

            // Mark comments as analyzed
            const batch = db.batch();
            comments.forEach((comment: Comment) => {
                batch.update(db.collection('videoComments').doc(comment.id), {
                    analyzed: true
                });
            });
            await batch.commit();
            
            console.log(`Successfully processed video ${videoId}`);

        } catch (error) {
            console.error(`Error processing video ${videoId}:`, error);
            await db.collection('videoAnalytics')
                .doc(videoId)
                .set({
                    batchStatus: 'failed'
                }, { merge: true });
        }
    }
    
    console.log("Comment analysis completed");
}

async function analyzeComments(comments: Comment[], openai: OpenAI): Promise<AnalysisResult> {
    const prompt = `Analyze these comments and provide a JSON response with:
    {
        "sentiment": (number between 0-1),
        "topics": {
            "topic1": count,
            "topic2": count,
            ...
        }
    }
    
    Comments:
    ${comments.map(c => c.content).join('\n')}`;

    const response = await openai.chat.completions.create({
        model: "gpt-4",
        messages: [{
            role: "system",
            content: "You are a comment analysis assistant. You must respond with valid JSON only."
        }, {
            role: "user",
            content: prompt
        }],
        temperature: 0 // Make responses more consistent
    });

    if (!response.choices[0].message.content) {
        throw new Error('No response from OpenAI');
    }

    try {
        return JSON.parse(response.choices[0].message.content) as AnalysisResult;
    } catch (error) {
        console.error('Failed to parse OpenAI response:', response.choices[0].message.content);
        throw new Error('Invalid JSON response from OpenAI');
    }
}

function calculateEngagement(comments: Comment[]): number {
    const totalLength = comments.reduce((sum, comment) => sum + comment.content.length, 0);
    const totalLikes = comments.reduce((sum, comment) => sum + (comment.likesCount || 0), 0);
    
    const avgLength = totalLength / comments.length;
    const avgLikes = totalLikes / comments.length;
    
    return (avgLength * 0.3) + (avgLikes * 0.7);
} 