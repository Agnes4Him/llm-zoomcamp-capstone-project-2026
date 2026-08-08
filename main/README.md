## Sample Questions
What benefits are included in my plan?

Does my plan cover dental treatment?

Does my plan cover physiotherapy?

Does my plan cover mental health services?

Does my plan cover specialist appointments?

How many physiotherapy sessions do I get per year?

Do I have maternity coverage?

Does my plan include emergency treatment?

Does my plan cover MRI scans?

What is my deductible?

How much of my deductible have I paid?

How much will I pay for a specialist visit?

How much does an MRI cost under my plan?

What percentage of treatment does insurance cover?

What is the status of my claim?

Why was my claim denied?

Has my claim been approved?

When will my claim be paid?

What is my latest claim?

Why is my claim still pending?

How long do claims usually take?

What documents are required for my claim?

Can I appeal a denied claim?

How do I submit a claim?

What documents do I need to submit a claim?

How long does claim processing take?

How do I appeal a rejected claim?

How long do I have to appeal a claim?

What reasons can cause a claim rejection?

What services require prior authorization?

Do I need approval before an MRI?

Do specialist visits require authorization?                      

How do I request prior authorization?

What happens if I receive treatment without authorization?              

How long does authorization take?                              

Who approves medical procedures?                    

How do I find a healthcare provider?             

Can I visit any hospital?                    

Do you have a preferred provider network?     

Is my doctor covered?

Can I change my healthcare provider?            

What happens if I use an out-of-network provider?        

Are emergency providers covered?

What is the difference between Bronze, Silver, and Gold plans?         

Which plan is best for families?              

Which plan is best for individuals?               

How much does insurance cost?                  

How do I become a member?

How do I sign up?

Can I cancel my plan?

How do I change plans?

What makes HealthSecure different?

How can I contact support?

What are your customer service hours?


## Sample Queries

### Recent activity + feedback
SELECT
  c.id,
  c.timestamp,
  c.question,
  c.model,
  c.prompt_tokens,
  c.completion_tokens,
  c.total_tokens,
  c.response_time,
  c.cost,
  f.id AS feedback_id,
  f.source,
  f.relevance,
  f.score,
  f.explanation,
  f.timestamp AS feedback_timestamp
FROM conversations c
LEFT JOIN feedbacks f
  ON f.conversation_id = c.id
ORDER BY c.timestamp DESC, f.id DESC
LIMIT 50;

### Average cost, latency, token usage over time
SELECT
  DATE("timestamp") AS day,
  COUNT(*) AS conversations,
  ROUND(AVG(response_time)::numeric, 4) AS avg_response_time,
  ROUND(AVG(cost)::numeric, 8) AS avg_cost,
  ROUND(AVG(prompt_tokens)::numeric, 1) AS avg_prompt_tokens,
  ROUND(AVG(completion_tokens)::numeric, 1) AS avg_completion_tokens,
  ROUND(AVG(total_tokens)::numeric, 1) AS avg_total_tokens,
  SUM(cost) AS total_cost
FROM conversations
GROUP BY DATE("timestamp")
ORDER BY day DESC
LIMIT 30;

### Model-level performance and cost
SELECT
  model,
  COUNT(*) AS calls,
  ROUND(AVG(response_time)::numeric, 4) AS avg_response_time,
  ROUND(MAX(response_time)::numeric, 4) AS max_response_time,
  ROUND(AVG(cost)::numeric, 8) AS avg_cost,
  SUM(cost) AS total_cost,
  ROUND(AVG(total_tokens)::numeric, 1) AS avg_total_tokens
FROM conversations
GROUP BY model
ORDER BY total_cost DESC;

### Slowest responses
SELECT
  id,
  timestamp,
  model,
  question,
  response_time,
  cost,
  total_tokens
FROM conversations
ORDER BY response_time DESC
LIMIT 20;

### Highest-cost calls
SELECT
  id,
  timestamp,
  model,
  question,
  cost,
  total_tokens,
  response_time
FROM conversations
ORDER BY cost DESC
LIMIT 20;

### Feedback volume and score distribution
SELECT
  source,
  COUNT(*) AS feedback_count,
  ROUND(AVG(score)::numeric, 2) AS avg_score,
  MIN(score) AS min_score,
  MAX(score) AS max_score
FROM feedbacks
GROUP BY source
ORDER BY feedback_count DESC;

SELECT
  score,
  COUNT(*) AS count
FROM feedbacks
GROUP BY score
ORDER BY score DESC;

### Conversations without feedback
SELECT
  c.id,
  c.timestamp,
  c.model,
  c.question,
  c.cost,
  c.response_time
FROM conversations c
LEFT JOIN feedbacks f
  ON f.conversation_id = c.id
WHERE f.id IS NULL
ORDER BY c.timestamp DESC
LIMIT 50;

### Correlate low feedback with cost or latency
SELECT
  c.id,
  c.timestamp,
  c.model,
  c.cost,
  c.response_time,
  c.total_tokens,
  f.score,
  f.relevance,
  f.source
FROM conversations c
JOIN feedbacks f
  ON f.conversation_id = c.id
WHERE f.score IS NOT NULL
ORDER BY f.score ASC, c.response_time DESC
LIMIT 50;

### Average feedback score by model
SELECT
  c.model,
  COUNT(*) AS feedback_count,
  ROUND(AVG(f.score)::numeric, 2) AS avg_score,
  ROUND(AVG(c.cost)::numeric, 8) AS avg_cost
FROM conversations c
JOIN feedbacks f
  ON f.conversation_id = c.id
WHERE f.score IS NOT NULL
GROUP BY c.model
ORDER BY avg_score DESC;