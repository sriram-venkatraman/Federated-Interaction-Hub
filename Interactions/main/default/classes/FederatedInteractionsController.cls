public class FederatedInteractionsController {
    @AuraEnabled
    public static List<Map<String, String>> fetchInteractions(List<String> lIds, 
                                                              List<String> selectedInteractionTypes,
                                                              String interactionStart,
                                                              String interactionEnd) {
        
        List<Map<String, String>> retList = new List<Map<String, String>>();
        String date1 = formatDate(interactionStart);
        String date2 = formatDate(interactionEnd);
        
        System.Debug('**** Selected Interaction Dates: ' + date1 + '|' + date2 );
        List<Interaction__x> iaList = [SELECT Id, ModifiedDate__c, InteractionDate__c, Type__c, Subject__c, Content__c, 
                                       			DisplayUrl, Owner__c, Name__c, VersionData__c, 
                                       			Account__c, Account__r.name, 
                                       			Opportunity__c, Opportunity__r.name,
                                       			HouseholdMember__c, HouseholdMember__r.name,
                                       			ExternalId 
                                       FROM  Interaction__x 
                                       WHERE Account__c = :lIds
                                       AND   Type__c = :selectedInteractionTypes];
//                                       AND   InteractionDate__c >= :interactionStart AND InteractionDate__c <= :interactionEnd];
             system.debug('### ia ' + iaList);   

        Map<String, String> m;
        for (Interaction__x i : iaList) {
            m = new Map<String, String>();
            m.put('Id', i.Id);
            m.put('ModifiedDate__c', i.ModifiedDate__c);
            m.put('InteractionDate__c', i.InteractionDate__c);
            m.put('Type__c', i.Type__c);
            m.put('Subject__c', i.Subject__c);
            m.put('Content__c', i.Content__c);
            m.put('DisplayUrl', i.DisplayUrl);
            m.put('Owner__c', i.Owner__c);
            m.put('Name__c', i.Name__c);
            m.put('VersionData__c', i.VersionData__c);
            m.put('Account__c', i.Account__c);
            m.put('AccountName', i.Account__r.name);
            m.put('AccountUrl', '/' + i.Account__c);
            if (i.Opportunity__c != null) {
                m.put('Opportunity__c', i.Opportunity__c);
                m.put('OpportunityName', i.Opportunity__r.name);
                m.put('OpportunityUrl', '/' + i.Opportunity__c);
            }
            if (i.Householdmember__c != null) {
                m.put('HouseholdMember__c', i.HouseholdMember__c);
                m.put('HouseholdMemberName', i.HouseholdMember__r.name);
                m.put('HouseholdMemberUrl', '/' + i.HouseholdMember__c);
            }
            m.put('ExternalId', i.ExternalId);
            
            retList.add(m);
        }
                                                                  
        system.debug('### ret ' + retList);   
                                                                  
        //return list of Interactions
        return retList;
    }
    
    private static String formatDate(String inDate) {
        List<String> months = new List<String>();
        String outDate = '';
        months.add('Jan');
        months.add('Feb');
        months.add('Mar');
        months.add('Apr');
        months.add('May');
        months.add('Jun');
        months.add('Jul');
        months.add('Aug');
        months.add('Sep');
        months.add('Oct');
        months.add('Nov');
        months.add('Dec');
        
        String[] inDateArray = inDate.split(' ');
        outDate = inDateArray[2] + '-' + 
                    (months.indexOf(inDateArray[0])+1).format().leftPad(2).replace(' ','0') + '-' + 
                    inDateArray[1].replace(',',' ').trim().leftPad(2).replace(' ','0');
        
        return outDate;      
    }
}