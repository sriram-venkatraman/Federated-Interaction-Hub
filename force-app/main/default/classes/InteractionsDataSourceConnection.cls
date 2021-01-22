global class InteractionsDataSourceConnection extends DataSource.Connection {
    List<String> lstIds = new List<String>();
    List<String> lstEIds = new List<String>();
    List<String> lstInteractionTypes = new List<String>();
    Map<String, String> mapOptyAcct = new Map<String, String>();
    
    global InteractionsDataSourceConnection(DataSource.ConnectionParams connectionParams) {
    }
    
    override global List<DataSource.Table> sync() {
        List<DataSource.Table> tables = new List<DataSource.Table>();        
        List<DataSource.Column> columns;
        columns = new List<DataSource.Column>();
        columns.add(DataSource.Column.lookup('Account', 'Account'));
        columns.add(DataSource.Column.lookup('HouseholdMember', 'Account'));
        columns.add(DataSource.Column.lookup('Opportunity', 'Opportunity'));
        columns.add(DataSource.Column.text('Name', 255));
        columns.add(DataSource.Column.text('ExternalId', 255));
        columns.add(DataSource.Column.text('Type', 255));
        columns.add(DataSource.Column.text('Status', 255));
        columns.add(DataSource.Column.text('Subject', 255));
        columns.add(DataSource.Column.text('Owner', 255));
        columns.add(DataSource.Column.text('InteractionDate', 25));
        columns.add(DataSource.Column.text('CreatedBy', 255));
        columns.add(DataSource.Column.text('CreatedDate', 25));
        columns.add(DataSource.Column.text('ModifiedBy', 255));
        columns.add(DataSource.Column.text('ModifiedDate', 25));
        columns.add(DataSource.Column.textarea('Content'));
        columns.add(DataSource.Column.textarea('VersionData'));
        columns.add(DataSource.Column.url('DisplayUrl'));
        tables.add(DataSource.Table.get('Interaction', 'Subject', columns));
        return tables;
    }
    
    override global DataSource.TableResult query(DataSource.QueryContext c) {
        Datasource.TableResult tableResult = null;
        try {
	        tableResult = DataSource.TableResult.get(c, DataSource.QueryUtils.process(c, getRows(c)));
		}
    	catch ( Exception e ) {
			e.getStackTraceString();
        }
        if (tableResult == null) {
            tableResult = Datasource.TableResult.get(c, new List<Map<String, Object>>());
        }
            
        return tableResult;
	}
    
/*    override global List<DataSource.TableResult> search(DataSource.SearchContext c) {        
        List<DataSource.TableResult> results = new List<DataSource.TableResult>();
        for (DataSource.TableSelection tableSelection : c.tableSelections) {
            results.add(DataSource.TableResult.get(tableSelection, getRows()));
        }
        return results;
    }
*/
    
    // Helper method to get record values from the external system for the Sample table.
    private List<Map<String, Object>> getRows (DataSource.QueryContext context) {
        try {
            // Get Parent Context aka list of What / Who Ids in lstIds
            getRequestIds( context.TableSelection.filter );   
        }
		catch ( Exception e ) {
			e.getStackTraceString();
        }

	    Map<String, String> acrRels = new Map<String, String>();    
        for ( AccountContactRelation acr : [ select accountid, contact.accountid from AccountContactRelation where accountid = :lstIds ] ) {
            lstIds.add(acr.contact.accountid);
            acrRels.put(acr.contact.accountid, acr.accountid);
        }

        // Collect all Opportunity for the given Accounts
        for (Opportunity o : [select Id, AccountId from Opportunity where AccountId = :lstIds]) {
            mapOptyAcct.put(o.Id, o.AccountId);
        }

        List<Map<String,Object>> rows = new List<Map<String,Object>>();
        List<Map<String,Object>> sortedRows = new List<Map<String,Object>>();
        Map<String,Object> row;
        lstIds.addAll(mapOptyAcct.keySet());
        
        // Get Events
        String eQuery = 'select Id, WhatId, Who.Name, StartDateTime, Subject, Description, Owner.Name, CreatedBy.Name, LastModifiedBy.Name, CreatedDate, LastModifiedDate from Event where ';
		if ( lstIds.size() > 0 ) eQuery += 'WhatId in :lstIds';
        if ( lstIds.size() > 0 && lstEIds.size() > 0 ) eQuery += ' and ';
		if ( lstEIds.size() > 0 ) eQuery += 'Id in :lstEIds';

		System.Debug('Sriram lstIds: ' + lstIds);
		System.Debug('Sriram lstEIds: ' + lstEIds);
		System.Debug('Sriram lstInteractionTypes: ' + lstInteractionTypes);
		System.Debug('Sriram Query Events: ' + eQuery);
        List<Event> le = Database.query(eQuery);
		System.Debug('Sriram List Events: ' + le);

        for (Event e : le) {
        	row = new Map<String,Object>();
            if (mapOptyAcct.get((String)e.WhatId) == null) {
                if (acrRels.get((String)e.WhatId) == null) {
                    row.put('Account', (String) e.WhatId);
                } else {
                    row.put('HouseholdMember', (String) e.WhatId);
                    row.put('Account', acrRels.get((String)e.WhatId));
                }
            } else {
                if (acrRels.get(mapOptyAcct.get((String)e.WhatId)) == null) {
	                row.put('Account', mapOptyAcct.get((String)e.WhatId));
                } else {
	                row.put('HouseholdMember', mapOptyAcct.get((String)e.WhatId));
                    row.put('Account', acrRels.get(mapOptyAcct.get((String)e.WhatId)));
                }
                row.put('Opportunity', (String) e.WhatId);
            }
            
            row.put('ExternalId', (String) e.Id);
            row.put('Name', (String) e.Who.Name);
            row.put('Type', 'Event');
            row.put('Owner', (String) e.Owner.Name);
            row.put('Subject', (String) e.Subject);
            row.put('InteractionDate', (String.valueOf(e.StartDateTime)));
            row.put('CreatedDate', (String.valueOf(e.CreatedDate)));
            row.put('ModifiedDate', (String.valueOf(e.LastModifiedDate)));
            row.put('CreatedBy', (String) e.CreatedBy.Name);
            row.put('ModifiedBy', (String) e.LastModifiedBy.Name);
            row.put('Content', (String) e.Description);
            row.put('DisplayUrl', (String) ('/' + e.Id));
            rows.add(row);
        }
        
        System.Debug('Sriram Rows size after Events: ' + rows.size());
        
        // Get Emails & Tasks
		Map<String, String> mem = new Map<String, String>();
        for (EmailMessage em : [select Id, ActivityId from EmailMessage where RelatedToId = :lstIds]) {
            mem.put(em.ActivityId, em.Id);
        }
        
        String tQuery = 'select Id, WhatId, Who.Name, ActivityDate, Subject, Description, Owner.Name, Status, CreatedBy.Name, LastModifiedBy.Name, CreatedDate, LastModifiedDate from Task where ';
		if ( lstIds.size() > 0 ) tQuery += 'WhatId = :lstIds';
        if ( lstIds.size() > 0 && lstEIds.size() > 0 ) tQuery += ' and ';
		if ( lstEIds.size() > 0 ) tQuery += 'Id = :lstEIds';

        List<Task> lt = Database.query(tQuery);
		System.Debug('Sriram List Tasks: ' + lt);
        
        for (Task t : lt) {
        	row = new Map<String,Object>();
            if (mapOptyAcct.get((String)t.WhatId) == null) {
                if (acrRels.get((String)t.WhatId) == null) {
                    row.put('Account', (String) t.WhatId);
                } else {
                    row.put('HouseholdMember', (String) t.WhatId);
                    row.put('Account', acrRels.get((String)t.WhatId));
                }
            } else {
                if (acrRels.get(mapOptyAcct.get((String)t.WhatId)) == null) {
	                row.put('Account', mapOptyAcct.get((String)t.WhatId));
                } else {
	                row.put('HouseholdMember', mapOptyAcct.get((String)t.WhatId));
                    row.put('Account', acrRels.get(mapOptyAcct.get((String)t.WhatId)));
                }
                row.put('Opportunity', (String) t.WhatId);
            }

            row.put('ExternalId', (String) t.Id);
            row.put('Name', (String) t.Who.Name);
            if (mem.get(t.Id) == null) {
            	row.put('Type', 'Task');
	            row.put('DisplayUrl', (String) ('/' + t.Id));
            }
            else {
            	row.put('Type', 'Email');
	            row.put('DisplayUrl', (String) ('/' + mem.get(t.Id)));                
            }
            row.put('Owner', (String) t.Owner.Name);
            row.put('Subject', (String) t.Subject);
            row.put('Status', (String) t.Status);
            row.put('InteractionDate', (String.valueOf(t.ActivityDate)));
            row.put('CreatedDate', (String.valueOf(t.CreatedDate)));
            row.put('ModifiedDate', (String.valueOf(t.LastModifiedDate)));
            row.put('CreatedBy', (String) t.CreatedBy.Name);
            row.put('ModifiedBy', (String) t.LastModifiedBy.Name);
            row.put('Content', (String) t.Description);
            rows.add(row);
        }

        System.Debug('Sriram Rows size after Tasks: ' + rows.size());
        
        // Get Notes
        List<String> lcdl = new List<String>();
        Map<String, String> mcdl = new Map<String, String>();
       	for (ContentDocumentLink c : [select ContentDocumentId, LinkedEntityId
                                      from 	 ContentDocumentLink 
                                      where  LinkedEntityId IN :lstIds]) {
        	lcdl.add(c.ContentDocumentId); 
            mcdl.put(c.ContentDocumentId, c.LinkedEntityId);
        }
            
        String cvQuery = 'select Id, ContentDocumentId, Title, TextPreview, FileType, CreatedBy.Name, LastModifiedBy.Name, CreatedDate, LastModifiedDate, VersionData from ContentVersion where ContentDocumentId = :lcdl and IsLatest = true  and IsDeleted = false  and FileType = \'SNOTE\' ';
        if ( lstIds.size() > 0 && lstEIds.size() > 0 ) cvQuery += ' and ';
		if ( lstEIds.size() > 0 ) cvQuery += 'Id = :lstEIds';

        List<ContentVersion> lcv = Database.query(cvQuery);
		System.Debug('Sriram List Notes: ' + lcv);
        String nWhatId;
        for (ContentVersion c : lcv) {
        	row = new Map<String,Object>();
            nWhatId = mcdl.get((String)c.ContentDocumentId);

            if (mapOptyAcct.get(nWhatId) == null) {
                if (acrRels.get(nWhatId) == null) {
                    row.put('Account', nWhatId);
                } else {
                    row.put('HouseholdMember', nWhatId);
                    row.put('Account', acrRels.get(nWhatId));
                }
            } else {
                if (acrRels.get(mapOptyAcct.get(nWhatId)) == null) {
	                row.put('Account', mapOptyAcct.get(nWhatId));
                } else {
	                row.put('HouseholdMember', mapOptyAcct.get(nWhatId));
                    row.put('Account', acrRels.get(mapOptyAcct.get(nWhatId)));
                }
                row.put('Opportunity', nWhatId);
            }

            row.put('ExternalId', (String) c.Id);
            row.put('Type', 'Note');
            row.put('Subject', (String) c.Title);
            row.put('InteractionDate', (String.valueOf(c.LastModifiedDate)));
            row.put('Content', (String) c.TextPreview);
            row.put('VersionData', c.VersionData.toString());
            row.put('DisplayUrl', (String) ('/' + c.ContentDocumentId));
            row.put('CreatedDate', (String.valueOf(c.CreatedDate)));
            row.put('ModifiedDate', (String.valueOf(c.LastModifiedDate)));
            row.put('CreatedBy', (String) c.CreatedBy.Name);
            row.put('ModifiedBy', (String) c.LastModifiedBy.Name);
            rows.add(row);
        }
        
        System.Debug('Sriram Rows size after Notes: ' + rows.size());
        
		sortedRows = getSortedResultList(rows);
        System.Debug('Sriram Rows size after sorting: ' + sortedRows.size());
        
        return sortedRows;
    }

    // This is a better version of getRequestIds with recurrsion
    private void getRequestIds( Datasource.Filter dsFilter ) {
        try {
            System.Debug('Sriram Filter: ' + dsFilter);
    
            if ( dsFilter.columnName == 'Account' ) {
                System.Debug('*** Found Account: ' + String.valueOf( dsFilter.columnValue ));
                lstIds.add( String.valueOf( dsFilter.columnValue ) );
            }
            if ( dsFilter.columnName == 'ExternalId' ) {
                System.Debug('*** Found ExternalId: ' + String.valueOf( dsFilter.columnValue ));
                lstEIds.add( String.valueOf( dsFilter.columnValue ) );
            }
            if ( dsFilter.columnName == 'Type' ) {
                System.Debug('*** Found Type: ' + String.valueOf( dsFilter.columnValue ));
                lstInteractionTypes.add( String.valueOf( dsFilter.columnValue ) );
            }
            
            if (dsFilter.subfilters != null) {
                System.Debug('**** Subfilter Size: ' + dsFilter.subfilters.size());
                for ( Datasource.Filter dsf : dsFilter.subfilters ) {
                    getRequestIds( dsf );
                }
            }
        } catch (exception e) {
            System.Debug('#### Error: ' + e.getMessage());
        }
        
        return;
    }
    
    private void DITCHTHISgetRequestIds( Datasource.Filter dsFilter ) {
//        lstIds = new List<String>();
//        lstEIds = new List<String>();

        System.Debug('Sriram Filter: ' + dsFilter);
        if ( dsFilter != null ) {
            // if Parent Context is Account
            if ( dsFilter != null && dsFilter.subfilters == null ) {
                if ( dsFilter.columnName == 'Account' ) lstIds.add( String.valueOf( dsFilter.columnValue ) );
                if ( dsFilter.columnName == 'ExternalId' ) lstEIds.add( String.valueOf( dsFilter.columnValue ) );
                if ( dsFilter.columnName == 'Type' ) lstInteractionTypes.add( String.valueOf( dsFilter.columnValue ) );
            }
            else if(dsFilter != null && dsFilter.subFilters != null && dsFilter.subFilters.size() == 1) {
                List<Datasource.Filter> dsSubFilters = dsFilter.subFilters;
                if ( dsSubFilters.get(0).columnName == 'Account' ) lstIds.add( String.valueOf( dsSubFilters.get(0).columnValue ) );
                if ( dsSubFilters.get(0).columnName == 'ExternalId' ) lstEIds.add( String.valueOf( dsSubFilters.get(0).columnValue ) );
                if ( dsSubFilters.get(0).columnName == 'Type' ) lstInteractionTypes.add( String.valueOf( dsSubFilters.get(0).columnValue ) );
            } 
            else if(dsFilter != null && dsFilter.subFilters != null && dsFilter.subFilters.size() >= 1){
                List<Datasource.Filter> dsSubFilters = dsFilter.subFilters;
                for(Integer i = 0; i < dsFilter.subFilters.size(); i++) {
                    if ( dsSubFilters[i].subFilters != null ) {
                       if ( dsSubFilters[i].subFilters.get(0).columnName == 'Account' ) lstIds.add(String.valueOf(dsSubFilters[i].subFilters.get(0).columnValue));
                       if ( dsSubFilters[i].subFilters.get(0).columnName == 'ExternalId' ) lstEIds.add(String.valueOf(dsSubFilters[i].subFilters.get(0).columnValue));
                       if ( dsSubFilters[i].subFilters.get(0).columnName == 'Type' ) lstInteractionTypes.add(String.valueOf(dsSubFilters[i].subFilters.get(0).columnValue));
                    }
                    else {
                       if ( dsSubFilters.get(i).columnName == 'Account' ) lstIds.add(String.valueOf(dsSubFilters.get(i).columnValue));
                       if ( dsSubFilters.get(i).columnName == 'ExternalId' ) lstEIds.add(String.valueOf(dsSubFilters.get(i).columnValue));
                       if ( dsSubFilters.get(i).columnName == 'Type' ) lstInteractionTypes.add(String.valueOf(dsSubFilters.get(i).columnValue));
                    }
                }
            }
        }
        
        System.Debug('Sriram List ID: ' + lstIds); 
        
        return;
    }
    
    private List<Map<String, Object>> getSortedResultList(List<Map<String, Object>> rawResultList){
        String identifierName ='';
        if(rawResultList != null && ! rawResultList.isEmpty() && rawResultList.size() > 1){
            Integer listSize = rawResultList.size();
            //start sorting :
            for(Integer i= 0; i<listSize-1; i++){
                Integer temIdx = i;
                for(Integer j =i+1;j<listSize;j++){
                    Map<String, Object> tempSelectedObj = rawResultList.get(temIdx);
                    Map<String, Object> tempNextObj = rawResultList.get(j);
                    if ( (String) tempSelectedObj.get('InteractionDate') < (String) tempNextObj.get('InteractionDate')) {
                        temIdx = j;
                    }               
                }
                Map<String, Object> tempObj = rawResultList.get(i);
                rawResultList.set(i,rawResultList.get(temIdx));
                rawResultList.set(temIdx,tempObj);
                
            }
        }
        return rawResultList;
        
    }
}