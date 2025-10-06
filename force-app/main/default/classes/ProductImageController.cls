public with sharing class ProductImageController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getProductImages(Id productId) {
        List<Map<String, String>> images = new List<Map<String, String>>();

        // Get Files (ContentDocumentLinks) related to product
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :productId
        ];

        for (ContentDocumentLink link : links) {
            Map<String, String> img = new Map<String, String>();
            img.put('Id', link.ContentDocumentId);
            img.put('Title', link.ContentDocument.Title);
            img.put('Url', '/sfc/servlet.shepherd/version/download/' + link.ContentDocument.LatestPublishedVersionId);
            images.add(img);
        }

        return images;
    }
}