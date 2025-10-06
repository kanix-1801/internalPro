public with sharing class ProductCatalogController {
        public class ProductWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String category;
        @AuraEnabled public String year;
        @AuraEnabled public List<String> imageUrls;

        public ProductWrapper(Id id, String name, String category, String year, List<String> imageUrls) {
            this.id = id;
            this.name = name;
            this.category = category;
            this.year = year;
            this.imageUrls = imageUrls;
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getFilteredProducts(String category, String year, String searchKey) {
        String query = 'SELECT Id, Name, Category__c, Year__c FROM Product2 WHERE ';
        List<String> filters = new List<String>();
        
        if (String.isNotBlank(category)) {
            filters.add('Category__c = :category');
        }
        if (String.isNotBlank(year)) {
            filters.add('Year__c = :year');
        }
        if (String.isNotBlank(searchKey)) {
            filters.add('Name LIKE \'%' + String.escapeSingleQuotes(searchKey) + '%\'');
        }
       
        if (filters.isEmpty()) {
            query += 'Id != NULL';
        } else {
            query += String.join(filters, ' AND ');
        }

        List<Product2> products = Database.query(query);
        List<Id> productIds = new List<Id>();

        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :productIds
        ];

        Set<Id> docIds = new Set<Id>();
        Map<Id, List<Id>> productToDocIds = new Map<Id, List<Id>>();

        for (ContentDocumentLink link : docLinks) {
            docIds.add(link.ContentDocumentId);
            if (!productToDocIds.containsKey(link.LinkedEntityId)) {
                productToDocIds.put(link.LinkedEntityId, new List<Id>());
            }
            productToDocIds.get(link.LinkedEntityId).add(link.ContentDocumentId);
        }

        Map<Id, String> docIdToImageUrl = new Map<Id, String>();
        for (ContentVersion ver : [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
            AND IsLatest = TRUE
        ]) {
            docIdToImageUrl.put(ver.ContentDocumentId, '/sfc/servlet.shepherd/version/download/' + ver.Id);
        }

        List<ProductWrapper> wrapped = new List<ProductWrapper>();
        for (Product2 p : products) {
            List<String> imageUrls = new List<String>();
            if (productToDocIds.containsKey(p.Id)) {
                for (Id docId : productToDocIds.get(p.Id)) {
                    if (docIdToImageUrl.containsKey(docId)) {
                        imageUrls.add(docIdToImageUrl.get(docId));

                        system.debug('imageUrls : '  + imageUrls);
                    }
                }
            }

            wrapped.add(new ProductWrapper(
                p.Id,
                p.Name,
                p.Category__c,
                p.Year__c,
                imageUrls
            ));
        }

        return wrapped;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCategoryOptions() {
        return new List<String>{'Sports Day', 'Festival', 'Trip'};
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getYearOptions() {
        return new List<String>{'2025', '2024', '2023', '2022'};
    }
}