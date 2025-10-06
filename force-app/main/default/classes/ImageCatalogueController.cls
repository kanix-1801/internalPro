public without sharing class ImageCatalogueController {
    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> getCategory() {
        List<Category__c> categories = [SELECT Id, Name FROM Category__c ];
        return wrapRecordsWithImages(categories);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> getSubCategory(Id categoryId) {
        List<Sub_Category__c> subCategories = [SELECT Id, Name, ImageCategory__c FROM Sub_Category__c WHERE ImageCategory__c = :categoryId ];
        return wrapRecordsWithImages(subCategories);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> getActualPictures(Id subCategoryId) {
        system.debug(subCategoryId);
        List<Actual_pictures__c> actualPictures = [SELECT Id, Name, Sub_Category__c FROM Actual_pictures__c WHERE Sub_Category__c = :subCategoryId ];
        system.debug( 'actualPictures' + actualPictures );
        return wrapRecordsWithImages(actualPictures);
    }
    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> getActualPicturesDemo() {
        List<Actual_pictures__c> actualPictures = [SELECT Id, Name, Sub_Category__c FROM Actual_pictures__c ];
        return wrapRecordsWithImages(actualPictures);
    }
    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> searchRecords(String searchName) {
        system.debug( 'searchName ' + searchName );
        List<sObject> results = new List<sObject>();
                if(String.isNotBlank(searchName)) {
            
                List<Sub_Category__c> subCategoryList= [
                    SELECT Id, Name, ImageCategory__c FROM Sub_Category__c 
                    WHERE Name LIKE :('%' + searchName + '%')     
                ];
                if ( !subCategoryList.isEmpty() ){
                    results.addAll( subCategoryList );
                }else{
                        List<Category__c > CategoryList = [
                        SELECT Id, Name FROM Category__c 
                        WHERE Name LIKE :('%' + searchName + '%') 
                        ];
                    if ( !CategoryList.isEmpty() ){
                        results.addAll( CategoryList );
                    }  
                }
            }
        
   
        
         return wrapRecordsWithImages(results);
    }
    
    private static List<RecordWrapper> wrapRecordsWithImages(List<sObject> records) {
        List<RecordWrapper> wrapped = new List<RecordWrapper>();
        if(records.isEmpty()) return wrapped;

        Set<Id> recordIds = new Set<Id>();
        for(sObject rec : records) recordIds.add(rec.Id);

        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :recordIds
        ];

        Map<Id, List<Id>> recordToDocIds = new Map<Id, List<Id>>();
        Set<Id> docIds = new Set<Id>();
        for(ContentDocumentLink link : docLinks) {
            docIds.add(link.ContentDocumentId);
            if(!recordToDocIds.containsKey(link.LinkedEntityId)) {
                recordToDocIds.put(link.LinkedEntityId, new List<Id>());
            }
            recordToDocIds.get(link.LinkedEntityId).add(link.ContentDocumentId);
        }

        Map<Id, String> docIdToUrl = new Map<Id, String>();
        for(ContentVersion ver : [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds AND IsLatest = TRUE
        ]) {
            docIdToUrl.put(ver.ContentDocumentId, '/sfc/servlet.shepherd/version/download/' + ver.Id);
            // docIdToUrl.put(ver.ContentDocumentId, '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB120BY90&versionId=' + ver.Id);
        }

        for(sObject rec : records) {
            List<String> imageUrls = new List<String>();
            if(recordToDocIds.containsKey(rec.Id)) {
                for(Id docId : recordToDocIds.get(rec.Id)) {
                    if(docIdToUrl.containsKey(docId)) imageUrls.add(docIdToUrl.get(docId));
                }
            }
            wrapped.add(new RecordWrapper((Id)rec.get('Id'), (String)rec.get('Name'), imageUrls));
        }

        return wrapped;
    }

    public class RecordWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public List<String> imageUrls;

        public RecordWrapper(Id id, String name, List<String> imageUrls) {
            this.id = id;
            this.name = name;
            this.imageUrls = imageUrls;
        }
    }

}