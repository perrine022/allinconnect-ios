# Push Notifications - Backend Implementation Guide

## Overview

This document describes the backend implementation required for push notifications when offers are created. The iOS app (`PushManager.swift`) handles device token registration, but the backend needs to implement the notification sending logic.

## Backend Requirements

### 1. Event System

When an offer is created in `OfferService.createOffer`, publish an application event:

```java
// Example in Java/Spring Boot
@EventListener
public void onOfferCreated(OfferCreatedEvent event) {
    // Event contains: offerId
    offerPushNotifier.notifyOfferCreated(event.getOfferId());
}
```

**Event Structure:**
```java
public class OfferCreatedEvent {
    private final Integer offerId;
    
    public OfferCreatedEvent(Integer offerId) {
        this.offerId = offerId;
    }
    
    public Integer getOfferId() {
        return offerId;
    }
}
```

### 2. OfferPushNotifier Service

Create a service that:
- Loads active iOS device tokens in pages of 1000
- Sends push notifications asynchronously with bounded concurrency (e.g., 50 parallel)
- Implements retry with exponential backoff for transient failures
- Logs metrics

**Example Implementation (Java/Spring Boot):**

```java
@Service
public class OfferPushNotifier {
    
    private static final int PAGE_SIZE = 1000;
    private static final int MAX_CONCURRENT = 50;
    private final ExecutorService executorService;
    private final PushTokenRepository pushTokenRepository;
    private final APNsService apnsService;
    private final MetricsLogger metricsLogger;
    
    @Autowired
    public OfferPushNotifier(
        PushTokenRepository pushTokenRepository,
        APNsService apnsService,
        MetricsLogger metricsLogger
    ) {
        this.pushTokenRepository = pushTokenRepository;
        this.apnsService = apnsService;
        this.metricsLogger = metricsLogger;
        this.executorService = Executors.newFixedThreadPool(MAX_CONCURRENT);
    }
    
    public void notifyOfferCreated(Integer offerId) {
        CompletableFuture.runAsync(() -> {
            try {
                int page = 0;
                List<PushToken> tokens;
                
                do {
                    tokens = pushTokenRepository.findActiveIOSTokens(
                        PageRequest.of(page, PAGE_SIZE)
                    );
                    
                    if (!tokens.isEmpty()) {
                        sendNotificationsInBatches(tokens, offerId);
                    }
                    
                    page++;
                } while (tokens.size() == PAGE_SIZE);
                
                metricsLogger.log("offer_notifications_sent", 
                    Map.of("offerId", offerId, "totalPages", page));
                    
            } catch (Exception e) {
                metricsLogger.logError("offer_notification_failed", 
                    Map.of("offerId", offerId), e);
            }
        }, executorService);
    }
    
    private void sendNotificationsInBatches(
        List<PushToken> tokens, 
        Integer offerId
    ) {
        List<CompletableFuture<Void>> futures = tokens.stream()
            .map(token -> CompletableFuture.runAsync(() -> 
                sendWithRetry(token, offerId), executorService))
            .collect(Collectors.toList());
            
        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
            .join();
    }
    
    private void sendWithRetry(PushToken token, Integer offerId) {
        int maxRetries = 3;
        long baseDelayMs = 1000; // 1 second
        
        for (int attempt = 0; attempt < maxRetries; attempt++) {
            try {
                apnsService.sendNotification(
                    token.getToken(),
                    buildNotificationPayload(offerId)
                );
                
                metricsLogger.log("push_notification_sent", 
                    Map.of("tokenId", token.getId(), "offerId", offerId));
                return;
                
            } catch (TransientException e) {
                if (attempt < maxRetries - 1) {
                    long delay = baseDelayMs * (long) Math.pow(2, attempt);
                    try {
                        Thread.sleep(delay);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        return;
                    }
                } else {
                    metricsLogger.logError("push_notification_failed_after_retries",
                        Map.of("tokenId", token.getId(), "offerId", offerId), e);
                }
            } catch (Exception e) {
                metricsLogger.logError("push_notification_error",
                    Map.of("tokenId", token.getId(), "offerId", offerId), e);
                return;
            }
        }
    }
    
    private Map<String, Object> buildNotificationPayload(Integer offerId) {
        return Map.of(
            "aps", Map.of(
                "alert", Map.of(
                    "title", "Nouvelle offre disponible",
                    "body", "Découvrez notre nouvelle offre !"
                ),
                "sound", "default",
                "badge", 1
            ),
            "offerId", offerId.toString(),
            "type", "offer_created"
        );
    }
}
```

### 3. Database Schema

Store device tokens in a table:

```sql
CREATE TABLE push_tokens (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(255) NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    platform VARCHAR(50) NOT NULL, -- 'ios' or 'android'
    environment VARCHAR(50) NOT NULL, -- 'prod' or 'dev'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_platform_active (platform, is_active)
);
```

### 4. API Endpoint

The iOS app sends device tokens to:

**POST /api/push/register**

Request Body:
```json
{
  "userId": "123",
  "token": "abc123...",
  "platform": "ios",
  "environment": "prod"
}
```

Response: `200 OK` or `201 Created`

### 5. APNs Integration

Use a library like:
- **Java**: `com.eatthepath:pushy` or `com.notnoop.apns:apns`
- **Node.js**: `apn` package
- **Python**: `PyAPNs2`

Configure with:
- Production/Development certificates
- Key ID and Team ID for token-based authentication
- Bundle ID matching your iOS app

### 6. Metrics and Logging

Log the following metrics:
- Total notifications sent per offer
- Success/failure rates
- Retry counts
- Average delivery time
- Token invalidation events

## Testing

1. **Unit Tests**: Test retry logic, batching, and error handling
2. **Integration Tests**: Test with APNs sandbox environment
3. **Load Tests**: Verify performance with large token lists (10k+)

## Notes

- Use APNs Production environment for `environment: "prod"`
- Use APNs Sandbox environment for development/testing
- Handle token invalidation (remove tokens that fail with 410 status)
- Consider rate limiting to avoid APNs throttling
- Monitor APNs feedback service for invalid tokens












