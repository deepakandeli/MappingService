public class MappingService {
	static String ObjectAPIName='ObjectAPIName';

    /* Initial method where Source and Target  objects are mapped to each other  */
    public static void mapSrcToTarget(String mappingName,Sobject srcObj,Sobject targObj){
	   	Map<String,String> mapOfSourceFields=new Map<String,String> ();
    	Map<String,String> mapOfTargetFields=new Map<String,String> ();
		getMappings(mappingName,mapOfSourceFields,mapOfTargetFields);
		getMappedTargetSObject(srcObj,targObj,mapOfSourceFields,mapOfTargetFields);
    }
    
    /* This is a generic method that prepares mapsof Source object fields and target object fields */
    public static void getMappings(String qualifiedApiName,Map<String,String> mapOfSourceFields,Map<String,String> mapOfTargetFields){
    	String sourceObj='';
    	String targetObj='';
	   	Set<String> setOfSourceFields=new Set<String> ();
    	Set<String> setOfTargetFields=new Set<String> ();
    	
    	Map<String, Schema.SObjectField> fldObjMap = schema.SObjectType.MappingService__mdt.fields.getMap();
    	List<Schema.SObjectField> fldObjMapValues = fldObjMap.values();
	    String theQuery = 'SELECT ';
        //seperate out source and target fields
        for(Schema.SObjectField s : fldObjMapValues){
            String theLabel = s.getDescribe().getLabel();
            String theName = s.getDescribe().getName();
            if(String.isNotBlank(theLabel) && theLabel.startsWith('Source Field')){
                setOfSourceFields.add(theName);
            }else if(String.isNotBlank(theLabel) && theLabel.startsWith('Target Field')){
                setOfTargetFields.add(theName);
            }else if(String.isNotBlank(theLabel) && theLabel.startsWith('Source Object')){
                sourceObj=theName;
            }else if(String.isNotBlank(theLabel) && theLabel.startsWith('Target Object')){
                targetObj=theName;
            }
            // Continue building your dynamic query string
            if(!theName.equalsIgnoreCase('Developername')){
                theQuery += theName + ',';
            }
        }
        // Trim last comma
        theQuery = theQuery.subString(0, theQuery.length() - 1);
        
        // Finalize query string
        theQuery += ' FROM MappingService__mdt WHERE QualifiedApiName=:qualifiedApiName';
        //System.debug('theQuery '+theQuery);
        SObject ms=Database.query(theQuery);

    	String src=(String)ms.get(sourceObj);
    	String targ=(String)ms.get(targetObj);

    	//System.debug('src = '+src+' targ = '+targ);
    	mapOfSourceFields.put(ObjectAPIName,src);
    	mapOfTargetFields.put(ObjectAPIName,targ);
    	
    	for(String curField:setOfSourceFields){
    		String curMapValue=(String)ms.get(curField);
    		if(String.isNotBlank(curMapValue)){
    			mapOfSourceFields.put(curField,curMapValue);
    		}
    	}
    	
    	for(String curField:setOfTargetFields){
    		String curMapValue=(String)ms.get(curField);
    		if(String.isNotBlank(curMapValue)){
    			mapOfTargetFields.put(curField,curMapValue);
    		}
    	}
    	//System.debug('mapOfSourceFields = '+mapOfSourceFields);
    	//System.debug('mapOfTargetFields = '+mapOfTargetFields);
    }

    /* Final method that fetches Source object data and Target object data  */
    public static void getMappedTargetSObject(SObject srcObj,SObject targObj,Map<String,String> mapOfSourceFields,
    								Map<String,String> mapOfTargetFields){
		for(String curSrcMapField:mapOfSourceFields.keySet()){
			if(!curSrcMapField.equalsIgnoreCase(ObjectAPIName)){
				String curSrcFieldName=mapOfSourceFields.get(curSrcMapField);
				//System.debug('cur Src Field Name = '+curSrcFieldName);
				//System.debug('cur Src Field Value = '+srcObj.get(curSrcFieldName));

				String curTarMapField=curSrcMapField.replace('Source','Target');
				//System.debug('curTarMapField = '+curTarMapField);
				if(mapOfTargetFields.containsKey(curTarMapField)){
					String curTargFieldName=mapOfTargetFields.get(curTarMapField);
					//System.debug('cur targ Field Name = '+curTargFieldName);
					targObj.put(curTargFieldName,srcObj.get(curSrcFieldName));
				}
			}
		}
    }
}