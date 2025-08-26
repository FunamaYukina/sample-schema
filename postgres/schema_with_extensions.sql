-- PostgreSQL Schema with Extensions (pgvector, pg_stat_statements, etc.)
-- Requires PostgreSQL 15+ with pgvector extension installed

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgvector";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gist";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create custom types
CREATE TYPE content_status AS ENUM ('draft', 'published', 'archived', 'deleted');
CREATE TYPE processing_status AS ENUM ('pending', 'processing', 'completed', 'failed');

-- Users table with vector embeddings for recommendation system
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    bio TEXT,
    profile_embedding vector(768), -- User profile vector for recommendations
    preferences_embedding vector(512), -- User preferences vector
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create index for vector similarity search
CREATE INDEX idx_users_profile_embedding ON users USING ivfflat (profile_embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_users_preferences_embedding ON users USING ivfflat (preferences_embedding vector_cosine_ops) WITH (lists = 50);
CREATE INDEX idx_users_metadata ON users USING gin (metadata);
CREATE INDEX idx_users_username_trgm ON users USING gist (username gist_trgm_ops);

-- Content table with vector embeddings for semantic search
CREATE TABLE content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    body TEXT NOT NULL,
    summary TEXT,
    content_embedding vector(1536), -- OpenAI ada-002 embedding dimension
    image_embedding vector(512), -- Image feature vector
    status content_status DEFAULT 'draft',
    tags TEXT[],
    view_count BIGINT DEFAULT 0,
    like_count BIGINT DEFAULT 0,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb,
    tsv tsvector GENERATED ALWAYS AS (to_tsvector('english', title || ' ' || COALESCE(body, ''))) STORED
);

-- Indexes for content
CREATE INDEX idx_content_embedding ON content USING ivfflat (content_embedding vector_cosine_ops) WITH (lists = 200);
CREATE INDEX idx_content_image_embedding ON content USING ivfflat (image_embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_content_tsv ON content USING gin (tsv);
CREATE INDEX idx_content_tags ON content USING gin (tags);
CREATE INDEX idx_content_status ON content (status);
CREATE INDEX idx_content_user_id ON content (user_id);
CREATE INDEX idx_content_published_at ON content (published_at DESC) WHERE status = 'published';

-- Real-time notifications using LISTEN/NOTIFY
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ
);

CREATE INDEX idx_notifications_user_unread ON notifications (user_id, created_at DESC) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_expires ON notifications (expires_at) WHERE expires_at IS NOT NULL;

-- Function to send real-time notifications
CREATE OR REPLACE FUNCTION notify_new_notification()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify(
        'new_notification',
        json_build_object(
            'user_id', NEW.user_id,
            'notification_id', NEW.id,
            'type', NEW.type,
            'title', NEW.title
        )::text
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_new_notification
AFTER INSERT ON notifications
FOR EACH ROW
EXECUTE FUNCTION notify_new_notification();

-- Media processing queue with vector embeddings
CREATE TABLE media_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    file_size BIGINT,
    status processing_status DEFAULT 'pending',
    processing_started_at TIMESTAMPTZ,
    processing_completed_at TIMESTAMPTZ,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    extracted_text TEXT,
    text_embedding vector(1536),
    visual_embedding vector(2048), -- ResNet or Vision Transformer embedding
    audio_embedding vector(768), -- Audio feature vector
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_media_queue_status ON media_queue (status, created_at);
CREATE INDEX idx_media_queue_text_embedding ON media_queue USING ivfflat (text_embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_media_queue_visual_embedding ON media_queue USING ivfflat (visual_embedding vector_cosine_ops) WITH (lists = 150);
CREATE INDEX idx_media_queue_audio_embedding ON media_queue USING ivfflat (audio_embedding vector_cosine_ops) WITH (lists = 50);

-- Similarity search results cache
CREATE TABLE search_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_embedding vector(1536) NOT NULL,
    query_text TEXT,
    search_type VARCHAR(50) NOT NULL,
    results JSONB NOT NULL,
    result_count INTEGER,
    avg_similarity_score FLOAT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '1 hour')
);

CREATE INDEX idx_search_cache_embedding ON search_cache USING ivfflat (query_embedding vector_cosine_ops) WITH (lists = 50);
CREATE INDEX idx_search_cache_expires ON search_cache (expires_at);

-- Real-time collaboration sessions
CREATE TABLE collaboration_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id VARCHAR(100) UNIQUE NOT NULL,
    content_id UUID REFERENCES content(id) ON DELETE CASCADE,
    participants UUID[] DEFAULT ARRAY[]::UUID[],
    active_users INTEGER DEFAULT 0,
    session_data JSONB DEFAULT '{}'::jsonb,
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_collaboration_sessions_room ON collaboration_sessions (room_id) WHERE is_active = TRUE;
CREATE INDEX idx_collaboration_sessions_participants ON collaboration_sessions USING gin (participants);

-- Analytics events with time-series optimization
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id UUID,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB DEFAULT '{}'::jsonb,
    page_url TEXT,
    referrer_url TEXT,
    user_agent TEXT,
    ip_address INET,
    geolocation POINT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (created_at);

-- Create monthly partitions for analytics
CREATE TABLE analytics_events_2024_01 PARTITION OF analytics_events
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE analytics_events_2024_02 PARTITION OF analytics_events
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE analytics_events_2024_03 PARTITION OF analytics_events
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

-- Indexes on partitioned table
CREATE INDEX idx_analytics_events_user_id ON analytics_events (user_id, created_at DESC);
CREATE INDEX idx_analytics_events_type ON analytics_events (event_type, created_at DESC);
CREATE INDEX idx_analytics_events_session ON analytics_events (session_id);

-- Recommendations table using vector similarity
CREATE TABLE recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_id UUID NOT NULL REFERENCES content(id) ON DELETE CASCADE,
    similarity_score FLOAT NOT NULL,
    recommendation_type VARCHAR(50) NOT NULL,
    context_embedding vector(768),
    is_viewed BOOLEAN DEFAULT FALSE,
    is_clicked BOOLEAN DEFAULT FALSE,
    feedback_score INTEGER CHECK (feedback_score BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'),
    UNIQUE(user_id, content_id, recommendation_type)
);

CREATE INDEX idx_recommendations_user ON recommendations (user_id, similarity_score DESC) WHERE is_viewed = FALSE;
CREATE INDEX idx_recommendations_expires ON recommendations (expires_at);

-- Function to find similar content using vector similarity
CREATE OR REPLACE FUNCTION find_similar_content(
    query_embedding vector(1536),
    limit_count INTEGER DEFAULT 10,
    similarity_threshold FLOAT DEFAULT 0.7
)
RETURNS TABLE (
    content_id UUID,
    title VARCHAR(500),
    similarity_score FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.title,
        1 - (c.content_embedding <=> query_embedding) as similarity_score
    FROM content c
    WHERE c.status = 'published'
        AND c.content_embedding IS NOT NULL
        AND 1 - (c.content_embedding <=> query_embedding) > similarity_threshold
    ORDER BY c.content_embedding <=> query_embedding
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to recommend content for user based on profile similarity
CREATE OR REPLACE FUNCTION recommend_for_user(
    target_user_id UUID,
    limit_count INTEGER DEFAULT 20
)
RETURNS TABLE (
    content_id UUID,
    title VARCHAR(500),
    author_id UUID,
    relevance_score FLOAT
) AS $$
DECLARE
    user_embedding vector(768);
BEGIN
    SELECT profile_embedding INTO user_embedding 
    FROM users WHERE id = target_user_id;
    
    IF user_embedding IS NULL THEN
        RETURN;
    END IF;
    
    RETURN QUERY
    SELECT 
        c.id,
        c.title,
        c.user_id,
        1 - (c.content_embedding <=> user_embedding) as relevance_score
    FROM content c
    LEFT JOIN recommendations r ON r.content_id = c.id AND r.user_id = target_user_id
    WHERE c.status = 'published'
        AND c.user_id != target_user_id
        AND c.content_embedding IS NOT NULL
        AND r.id IS NULL
    ORDER BY c.content_embedding <=> user_embedding
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Materialized view for popular content with vectors
CREATE MATERIALIZED VIEW popular_content AS
SELECT 
    c.id,
    c.title,
    c.user_id,
    u.username,
    c.content_embedding,
    c.view_count,
    c.like_count,
    (c.view_count * 0.3 + c.like_count * 0.7) as popularity_score,
    c.published_at
FROM content c
JOIN users u ON u.id = c.user_id
WHERE c.status = 'published'
    AND c.published_at > CURRENT_TIMESTAMP - INTERVAL '30 days'
ORDER BY popularity_score DESC
LIMIT 1000;

CREATE INDEX idx_popular_content_embedding ON popular_content USING ivfflat (content_embedding vector_cosine_ops) WITH (lists = 50);

-- Trigger for updating updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_content_updated_at BEFORE UPDATE ON content FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_media_queue_updated_at BEFORE UPDATE ON media_queue FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Function to clean up expired data
CREATE OR REPLACE FUNCTION cleanup_expired_data()
RETURNS void AS $$
BEGIN
    DELETE FROM search_cache WHERE expires_at < CURRENT_TIMESTAMP;
    DELETE FROM recommendations WHERE expires_at < CURRENT_TIMESTAMP;
    DELETE FROM notifications WHERE expires_at < CURRENT_TIMESTAMP AND expires_at IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- Comments for documentation
COMMENT ON TABLE users IS 'User profiles with vector embeddings for personalization';
COMMENT ON TABLE content IS 'Content items with semantic search capabilities using vector embeddings';
COMMENT ON TABLE media_queue IS 'Media processing queue with multi-modal embeddings';
COMMENT ON TABLE notifications IS 'Real-time notifications with LISTEN/NOTIFY support';
COMMENT ON TABLE analytics_events IS 'Time-series analytics data with partitioning';
COMMENT ON TABLE recommendations IS 'AI-powered content recommendations using vector similarity';
COMMENT ON COLUMN users.profile_embedding IS 'Vector embedding representing user profile for recommendation algorithms';
COMMENTongresql";