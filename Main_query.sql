-- creating all the tables

-- Table-1 Calls

CREATE TABLE calls (
    call_id BIGINT PRIMARY KEY,
    customer_id BIGINT,
    agent_id BIGINT,
    call_start_datetime TIMESTAMP,
    agent_assigned_datetime TIMESTAMP,
    call_end_datetime TIMESTAMP,
    call_transcript TEXT
);

SET datestyle = 'ISO, MDY';


COPY calls(call_id, customer_id, agent_id, call_start_datetime, agent_assigned_datetime, call_end_datetime, call_transcript)
FROM 'C:\UA\calls.csv'
DELIMITER ','
CSV HEADER;

-- Table-2 Reason

CREATE TABLE reason (
    call_id BIGINT,
    primary_call_reason VARCHAR(255)
);
COPY reason(call_id, primary_call_reason)
FROM 'C:\UA\reason.csv'
DELIMITER ','
CSV HEADER;

-- Table-3 customers
CREATE TABLE customers (
    customer_id BIGINT PRIMARY KEY,
    customer_name VARCHAR(255),
    elite_level_code INT
);
COPY customers(customer_id, customer_name, elite_level_code)
FROM 'C:\UA\customers.csv'
DELIMITER ','
CSV HEADER;

-- Table-4 sentiment_statistics
CREATE TABLE sentiment_statistics (
    call_id BIGINT,
    agent_id BIGINT,
    agent_tone VARCHAR(50),
    customer_tone VARCHAR(50),
    average_sentiment FLOAT,
    silence_percent_average FLOAT
);
COPY sentiment_statistics(call_id, agent_id, agent_tone, customer_tone, average_sentiment, silence_percent_average)
FROM 'C:\UA\sentiment_statistics.csv'
DELIMITER ','
CSV HEADER;

-- Table-5 test
CREATE TABLE call_records (
    call_id BIGINT PRIMARY KEY
);
COPY call_records(call_id)
FROM 'C:\UA\test.csv'
DELIMITER ','
CSV HEADER;

-- Calculate Average Handle Time (AHT) and Average Speed to Answer (AST)
WITH cleaned_reasons AS (
    SELECT 
        call_id,
        LOWER(REPLACE(REGEXP_REPLACE(TRIM(primary_call_reason), '\s+', ' ', 'g'), '-', ' ')) AS normalized_reason
    FROM 
        reason
),
call_metrics AS (
    SELECT 
        c.call_id,
        cr.normalized_reason,
        EXTRACT(EPOCH FROM (c.call_end_datetime - c.call_start_datetime)) AS handle_time_seconds,
        EXTRACT(EPOCH FROM (c.agent_assigned_datetime - c.call_start_datetime)) AS speed_to_answer_seconds,
        s.agent_tone,
        s.customer_tone,
        s.average_sentiment
    FROM 
        calls as c
    JOIN 
        cleaned_reasons as cr ON c.call_id = cr.call_id
    JOIN 
        sentiment_statistics as s ON c.call_id = s.call_id
)

SELECT 
    normalized_reason,
    AVG(handle_time_seconds) AS average_aht_seconds,
    AVG(speed_to_answer_seconds) AS average_ast_seconds,
    COUNT(*) AS total_calls
FROM 
    call_metrics
GROUP BY 
    normalized_reason
ORDER BY 
    total_calls DESC;
	
--  Calculate Average Handle Time (AHT) and Add Key Factors
WITH cleaned_reasons AS (
    SELECT 
        call_id,
        LOWER(REPLACE(REGEXP_REPLACE(TRIM(primary_call_reason), '\s+', ' ', 'g'), '-', ' ')) AS normalized_reason
    FROM 
        reason
),
call_metrics AS (
    SELECT 
        c.call_id,
        c.agent_id,
        cr.normalized_reason,
        EXTRACT(EPOCH FROM (c.call_end_datetime - c.call_start_datetime)) AS handle_time_seconds,
        s.agent_tone,
        s.customer_tone,
        s.average_sentiment
    FROM 
        calls c
    JOIN 
        cleaned_reasons cr ON c.call_id = cr.call_id
    JOIN 
        sentiment_statistics s ON c.call_id = s.call_id
)

SELECT 
    AVG(handle_time_seconds) AS average_aht_seconds,
    agent_tone,
    customer_tone,
    normalized_reason,
    AVG(average_sentiment)AS avg_sentiment_score,
    COUNT(*) AS total_calls
FROM 
    call_metrics
GROUP BY 
    agent_tone, customer_tone, normalized_reason
ORDER BY 
    average_aht_seconds DESC, total_calls DESC;
	
	
-- Determine High Volume Call Periods
-- Identify high volume call periods by grouping by day and hour
WITH call_volume AS (
    SELECT 
        DATE_TRUNC('hour', call_start_datetime) AS call_hour,
        COUNT(*) AS total_calls
    FROM 
        calls
    GROUP BY 
        call_hour
    ORDER BY 
        total_calls DESC
)

SELECT 
    call_hour,
    total_calls
FROM 
    call_volume
LIMIT 10; -- Top 10 highest volume hours

-- Calculate AHT and AST for Each Call
WITH call_metrics AS (
    SELECT 
        call_id,
        EXTRACT(EPOCH FROM (call_end_datetime - call_start_datetime)) AS handle_time_seconds,
        EXTRACT(EPOCH FROM (agent_assigned_datetime - call_start_datetime)) AS speed_to_answer_seconds
    FROM 
        calls
)

SELECT 
    call_id,
    handle_time_seconds,
    speed_to_answer_seconds
FROM 
    call_metrics;

-- Correlate AHT and AST with Call Volume
WITH call_volume AS (
    SELECT 
        DATE_TRUNC('hour', call_start_datetime) AS call_hour,
        COUNT(*) AS total_calls
    FROM 
        calls
    GROUP BY 
        call_hour
    ORDER BY 
        total_calls DESC
),
call_metrics AS (
    SELECT 
        c.call_id,
        DATE_TRUNC('hour', c.call_start_datetime) AS call_hour,
        EXTRACT(EPOCH FROM (c.call_end_datetime - c.call_start_datetime)) AS handle_time_seconds,
        EXTRACT(EPOCH FROM (c.agent_assigned_datetime - c.call_start_datetime)) AS speed_to_answer_seconds,
        s.agent_tone,
        s.customer_tone,
        cr.normalized_reason,
        s.average_sentiment
    FROM 
        calls c
    LEFT JOIN 
        reason r ON c.call_id = r.call_id
    LEFT JOIN 
        sentiment_statistics s ON c.call_id = s.call_id
    LEFT JOIN 
        (SELECT 
            call_id, 
            LOWER(REPLACE(REGEXP_REPLACE(TRIM(primary_call_reason), '\s+', ' ', 'g'), '-', ' ')) AS normalized_reason
         FROM reason) cr ON c.call_id = cr.call_id
)

SELECT 
    cm.call_hour,
    cm.handle_time_seconds,
    cm.speed_to_answer_seconds,
    cv.total_calls,
    cm.agent_tone,
    cm.customer_tone,
    cm.normalized_reason,
    cm.average_sentiment
FROM 
    call_metrics cm
JOIN 
    call_volume cv ON cm.call_hour = cv.call_hour
WHERE 
    cv.total_calls > 100 -- Consider hours with high call volume (adjust threshold as needed)
ORDER BY 
    cm.call_hour, cm.handle_time_seconds DESC;

-- Identify Key Drivers of Long AHT and AST
WITH call_volume AS (
    SELECT 
        DATE_TRUNC('hour', call_start_datetime) AS call_hour,
        COUNT(*) AS total_calls
    FROM 
        calls
    GROUP BY 
        call_hour
    ORDER BY 
        total_calls DESC
),
call_metrics AS (
    SELECT 
        c.call_id,
        DATE_TRUNC('hour', c.call_start_datetime) AS call_hour,
        EXTRACT(EPOCH FROM (c.call_end_datetime - c.call_start_datetime)) AS handle_time_seconds,
        EXTRACT(EPOCH FROM (c.agent_assigned_datetime - c.call_start_datetime)) AS speed_to_answer_seconds,
        s.agent_tone,
        s.customer_tone,
        cr.normalized_reason,
        s.average_sentiment
    FROM 
        calls c
    LEFT JOIN 
        (SELECT call_id, 
                LOWER(REPLACE(REGEXP_REPLACE(TRIM(primary_call_reason), '\s+', ' ', 'g'), '-', ' ')) AS normalized_reason
         FROM reason) cr ON c.call_id = cr.call_id
    LEFT JOIN 
        sentiment_statistics s ON c.call_id = s.call_id
)

SELECT 
    normalized_reason,
    agent_tone,
    customer_tone,
    AVG(handle_time_seconds) AS avg_handle_time,
    AVG(speed_to_answer_seconds) AS avg_speed_to_answer,
    COUNT(*) AS call_count,
    AVG(average_sentiment) AS avg_sentiment_score
FROM 
    call_metrics cm
JOIN 
    call_volume cv ON cm.call_hour = cv.call_hour
WHERE 
    cv.total_calls > 100 -- High call volume periods
GROUP BY 
    normalized_reason, agent_tone, customer_tone
ORDER BY 
    avg_handle_time DESC, avg_speed_to_answer DESC;

-- Percentage Difference

-- Step 1: Calculate the frequency of each call reason and find AHT for each reason
WITH reason_frequency AS (
    SELECT 
        LOWER(REPLACE(REGEXP_REPLACE(TRIM(primary_call_reason), '\s+', ' ', 'g'), '-', ' ')) AS normalized_reason,
        COUNT(*) AS call_count,
        AVG(EXTRACT(EPOCH FROM (c.call_end_datetime - c.call_start_datetime))) AS avg_handle_time_seconds
    FROM 
        calls c
    LEFT JOIN 
        reason r ON c.call_id = r.call_id
    GROUP BY 
        normalized_reason
),

-- Step 2: Find the most frequent and least frequent call reasons
most_frequent AS (
    SELECT 
        normalized_reason,
        avg_handle_time_seconds,
        call_count
    FROM 
        reason_frequency
    ORDER BY 
        call_count DESC
    LIMIT 1
),

least_frequent AS (
    SELECT 
        normalized_reason,
        avg_handle_time_seconds,
        call_count
    FROM 
        reason_frequency
    ORDER BY 
        call_count ASC
    LIMIT 1
)

-- Step 3: Calculate the absolute percentage difference between most frequent and least frequent call reasons
SELECT 
    mf.normalized_reason AS most_frequent_reason,
    mf.avg_handle_time_seconds AS most_frequent_aht,
    lf.normalized_reason AS least_frequent_reason,
    lf.avg_handle_time_seconds AS least_frequent_aht,
    ROUND(ABS((mf.avg_handle_time_seconds - lf.avg_handle_time_seconds) / mf.avg_handle_time_seconds) * 100, 2) AS absolute_percent_difference
FROM 
    most_frequent mf,
    least_frequent lf;

-- Step 1: Extract and preprocess call reasons and transcripts
WITH call_reason_transcripts AS (
    SELECT 
        LOWER(REPLACE(REGEXP_REPLACE(TRIM(r.primary_call_reason), '\s+', ' ', 'g'), '-', ' ')) AS normalized_reason,
        c.call_transcript,
        COUNT(*) AS frequency
    FROM 
        calls c
    LEFT JOIN 
        reason r ON c.call_id = r.call_id
    GROUP BY 
        normalized_reason, c.call_transcript
),

-- Step 2: Calculate frequency of each normalized reason
reason_frequency AS (
    SELECT 
        crt.normalized_reason,  -- Use the table alias 'crt' here to avoid ambiguity
        COUNT(*) AS total_calls
    FROM 
        call_reason_transcripts crt
    GROUP BY 
        crt.normalized_reason
    ORDER BY 
        total_calls DESC
)

-- Step 3: Identify top recurring reasons with corresponding transcripts
SELECT 
    crt.normalized_reason AS call_reason,
    crt.call_transcript,
    crt.frequency,
    rf.total_calls
FROM 
    call_reason_transcripts crt
JOIN 
    reason_frequency rf ON crt.normalized_reason = rf.normalized_reason
ORDER BY 
    rf.total_calls DESC, crt.frequency DESC
LIMIT 20;  -- Show the top 10 most frequent reasons and their transcripts for analysis
