# PrimoVE_Chromium

**IMPORTANT!**  
One of the following settings in the config.xml must be set to true in order for the Addon to work:

-- GoToLandingPage  
-- AutoSearchISxN  
-- AutoSearchTitle  

**Also IMPORTANT!**  
If you would like to have the Addon insert the Barcode for the item into the transaction from Primo, you must add an ILLiad field name to the config.xml file for the BarcodeLocation field.

**Example Configuration Values for Primo VE URL (from SUNY Geneseo)**


For SUNY Geneseo, the URL of the results page of a Primo query for "dogs" in the ILL staff's preferred tab and scope is:  
  
https://glocat.geneseo.edu/discovery/search?query=any,contains,dogs&tab=ALL_PHYSICAL&search_scope=ALL_PHYSICAL&vid=01SUNY_GEN:01SUNY_GEN&offset=0

**BaseURL:**  
Description:  This value is the path of the Primo URL before the ?  
Example:  https://suny-gen.primo.exlibrisgroup.com/discovery/search

**DatabaseName:**  
Description:  This is the value of the "vid" parameter in the URL.  
Example:  01SUNY_GEN:01SUNY_GEN

**SearchTab:**  
Description:  This value is the code of the tab to search, found in the "tab" parameter.  
Example:  ALL_PHYSICAL

**SearchScope:**  
Description:  This is the code of the scope to search within the tab, found in the "search_scope" parameter.  
Example:  ALL_PHYSICAL

**MaterialTypePhrase:**  
Description:  This is phrase used for format/material type in the 'Item in Place' box on the Primo item record.  
Example:  Material Type

**BarcodeField:**  
Description:  Defines which field to use in ILLiad to inserting the Barcode (example: ItemInfo5). This setting must contain a value in order to gather the Barcode.  
Example:  ItemInfo5




