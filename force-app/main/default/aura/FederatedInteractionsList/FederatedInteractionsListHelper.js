({
    fetchInActHelper : function(component, event, helper) {
        var actions = [
            { label: 'View Details', name: 'view_details' },
            { label: 'View Below', name: 'view_below' }
        ];
        component.set('v.mycolumns', [
            	{label: 'Interaction Date', fieldName: 'InteractionDate__c', type: 'date', 
                 initialWidth: 175,
                 typeAttributes: {
                    weekday: 'short',
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                }},
            	{label: 'Type', type: 'text', initialWidth: 80, 
                 	cellAttributes: { iconName: { fieldName: 'iconName' }, iconPosition: 'left', tooltip: 'Event' }
                },
            	{label: 'Subject', fieldName: 'Subject__c', type: 'text', initialWidth: 200},
                {label: 'Details', fieldName: 'Content__c', type: 'richtext', initialWidth: 400},
                {label: 'Owner', fieldName: 'Owner__c', type: 'text', initialWidth: 150},
            	{label: 'Household Member', fieldName: 'HouseholdMemberUrl', type: 'url', initialWidth: 200,
                	typeAttributes: { label: { fieldName: 'HouseholdMemberName' }, tooltip: { fieldName: 'HouseholdMemberName' } }
                },
            	{label: 'Opportunity', fieldName: 'OpportunityUrl', type: 'url', initialWidth: 200,
                	typeAttributes: { label: { fieldName: 'OpportunityName' }, tooltip: { fieldName: 'OpportunityName' } }
                },
            	{label: '', type: 'button', initialWidth: 135, initialWidth: 20, 
                 	typeAttributes: { label: '', name: 'view_below', variant: 'base', iconName: 'utility:preview', iconPosition: 'center', title: 'Click to View Details Below'}
            	},
				{label: '', type: 'button', initialWidth: 135, initialWidth: 20, 
                 	typeAttributes: { label: '', name: 'view_details', variant: 'base', iconName: 'utility:open', iconPosition: 'center', title: 'Click to View Details'}
            	}
        ]);
        
//	            {type: 'action', typeAttributes: { rowActions: actions, menuAlignment: 'left' } },
//				{label: '', type: 'buttonIcon', initialWidth: 135, initialWidth: 80, cellAttributes: { name: 'view', iconName: 'utility:preview',  title: 'Click to View Details'}}

        var action = component.get("c.fetchInteractions");
        action.setParams({
            "lIds": component.get("v.recordId"),
            "selectedInteractionTypes": component.get("v.selectedInteractionTypes"),
            "interactionStart": component.get("v.rangeStart"),
            "interactionEnd": component.get("v.rangeEnd")
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();

            if (state === "SUCCESS") {
                var dataList = response.getReturnValue();
                dataList = dataList.map(function(rowData) {
                    rowData.iconName = 'standard:' + rowData.Type__c.toLowerCase() ;
                    rowData.iconLabel = rowData.Type__c;
                    return rowData;
                });
                
                component.set("v.inActList", dataList);
            }
        });
        $A.enqueueAction(action);
    },

    showRowDetails : function(row) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": row.DisplayUrl.substring(1,19)
        });
        
        navEvt.fire();
        
        /* window.open(row.DisplayUrl,
                    "ModalPopUp",
                    "toolbar=no," +
                    "scrollbars=no," +
                    "location=no," +
                    "statusbar=no," +
                    "menubar=no," +
                    "resizable=0," +
                    "width=500," +
                    "height=600"
                    );*/
    },

    showRowDetailsBelow : function(row) {
        var appEvent = $A.get("e.c:InteractionViewEvent");
        var sObject;
        
        sObject = row.Type__c;
        if (row.Type__c == 'Email') sObject = 'EmailMessage';
        if (row.Type__c == 'Note') sObject = 'ContentNote';
        
        appEvent.setParams({
            "CurrentInteractionId" : row.DisplayUrl.substring(1,19),
            "HeaderMessage" : row.Subject__c,
            "SubHeaderMessage" : Date(row.ModifiedDate__c).toString(),
            "Icon" : "standard:" + row.Type__c.toLowerCase(),
            "VersionData" : row.VersionData__c,
            "SObject" : sObject
        });
        
        appEvent.fire();
    }
})