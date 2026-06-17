public with sharing class DMT_MiniChatterController {
    @AuraEnabled(cacheable=true)
    public static FeedItem getLatestComment(Id recordId) {
        List<FeedItem> feeds = [
            SELECT Id, Body, CreatedBy.Name, CreatedDate 
            FROM FeedItem 
            WHERE ParentId = :recordId 
              AND Type IN ('TextPost', 'LinkPost', 'ContentPost') 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        return feeds.isEmpty() ? null : feeds[0];
    }
}