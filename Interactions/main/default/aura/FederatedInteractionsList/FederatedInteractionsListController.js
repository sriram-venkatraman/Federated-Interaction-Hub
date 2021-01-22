({
    fetchInAct : function(component, event, helper) {
        var rangeEnd = (new Date(Date.now())).toString().split(" ");
        component.set("v.rangeEnd", rangeEnd[1] + " " + rangeEnd[2] + ", " + rangeEnd[3]);

        var rangeStart = (new Date(Date.now()-15552000000)).toString().split(" ");
        component.set("v.rangeStart", rangeStart[1] + " " + rangeStart[2] + ", " + rangeStart[3]);

        helper.fetchInActHelper(component, event, helper);
    },

    updateSelectedText: function (cmp, event) {
        var selectedRows = event.getParam('selectedRows');
        var CurrentAccountId = '';
        var SelectedExternalIds = '';
        cmp.set('v.selectedRowsCount', selectedRows.length);
        
        for (var i = 0; i < selectedRows.length; i++ ) {
            CurrentAccountId = selectedRows[i].Account__c;
            if (SelectedExternalIds != '') SelectedExternalIds += ',';
            SelectedExternalIds += selectedRows[i].ExternalId;
        }
        cmp.set('v.currentAccountId', CurrentAccountId);
        cmp.set('v.selectedExternalIds', SelectedExternalIds);
    },

    printInteractions: function (component, event, helper) {
        if (component.get('v.selectedExternalIds') == '' ) {
            alert('You have to select atleast one record from the list');
        }
        else {
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
              "url": "/apex/RenderInteractionsAsPDF?AccountIds=" + 
                     component.get('v.currentAccountId') + '&ExternalIds=' + component.get('v.selectedExternalIds')
            });
            urlEvent.fire();
        }
    },

    filterInteractions: function (component, event, helper) {
        if (component.get("v.showFilters") == false) {
	        component.set("v.showFilters", true);
        } else {
	        component.set("v.showFilters", false);
        }            
    },

    handleInteractionTypeSelection: function (component, event, helper) {
    },

    handleRowAction: function (cmp, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'view_details':
                helper.showRowDetails(row);
                break;
            case 'view_below':
                helper.showRowDetailsBelow(row);
                break;
            default:
                helper.showRowDetails(row);
                break;
        }
    }
})