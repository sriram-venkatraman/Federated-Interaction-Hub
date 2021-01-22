public class InteractionsListController {
    // ApexPages.StandardSetController must be instantiated
    // for standard list controllers
    // 
    List<String> AccountIds = new List<String>();
    List<String> ExternalIds = new List<String>();
    String AccountName = '';
    
    public String getAccountName() {
        Account a = [select Name from Account where Id = :AccountIds limit 1];
        return a.Name;
    }
    
    public ApexPages.StandardSetController setCon {
        get {
            if(setCon == null) {
                String iQuery = '';
                if (AccountIds.size() > 0) {
                	iQuery = 'SELECT Id, ModifiedDate__c, InteractionDate__c, Type__c, Subject__c, Content__c, ' +
                        	 'DisplayUrl, Owner__c, Name__c, VersionData__c, Account__r.Name, '+
                        	 'Opportunity__r.Name, HouseholdMember__r.Name ' +
                        	 'FROM Interaction__x ' +
                        	 'WHERE Account__c = :AccountIds ';
                    if (ExternalIds.size() > 0 ) {
                        iQuery += 'AND ExternalId = :ExternalIds';
                    }
                }
                
                System.Debug('Sriram Query Interactions: ' + iQuery);
                List<Interaction__x> li = Database.query(iQuery);
                System.Debug('Sriram List Interactions: ' + li);

                setCon = new ApexPages.StandardSetController(li);
            }
            return setCon;
        }
        set;
    }

    // Initialize setCon and return a list of records
    public List<Interaction__x> getInteractions() {
        try {
	        AccountIds = ApexPages.currentPage().getParameters().get('AccountIds').split(',');
        } catch(Exception e) {
            AccountIds = new List<String>();
        }
        
        System.Debug('Sriram AccountIds: ' + AccountIds);

        try {
       		ExternalIds = ApexPages.currentPage().getParameters().get('ExternalIds').split(',');
        } catch(Exception e) {
            ExternalIds = new List<String>();
        }

        System.Debug('Sriram ExternalIds: ' + ExternalIds);

        return (List<Interaction__x>) setCon.getRecords();
    }
}