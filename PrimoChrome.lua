-- About PrimoNewUI_Chromium.lua
--
-- Author: Bill Jones III, SUNY Geneseo, IDS Project, jonesw@geneseo.edu
-- PrimoNewUI_Chromium.lua provides a basic search for ISBN, ISSN, Title, and Phrase Searching for the Primo New UI interface.
-- There is a config file that is associated with this Addon that needs to be set up in order for the Addon to work.
-- Please see the ReadMe.txt file for example configuration values that you can pull from your Primo New UI URL.
--
-- IMPORTANT:  One of the following settings must be set to true in order for the Addon to work:
-- set GoToLandingPage to true for this script to automatically navigate to your instance of Primo New UI.
-- set AutoSearchISxN to true if you would like the Addon to automatically search for the ISxN.
-- set AutoSearchTitle to true if you would like the Addon to automatically search for the Title.
--
-- Modified 2020-02-11 by Tamara Marnell, Central Oregon Community College, libsys@cocc.edu

local settings = {};
settings.GoToLandingPage = GetSetting("GoToLandingPage");
settings.AutoSearchISxN = GetSetting("AutoSearchISxN");
settings.AutoSearchTitle = GetSetting("AutoSearchTitle");
settings.PrimoVE = GetSetting("PrimoVE");
settings.BaseURL = GetSetting("BaseURL");
settings.DatabaseName = GetSetting("DatabaseName");
settings.SearchTab = GetSetting("SearchTab");
settings.SearchScope = GetSetting("SearchScope");
settings.AutoSave = GetSetting("AutoSave");

local params = "tab=" .. settings.SearchTab .. "&search_scope=" .. settings.SearchScope .. "&vid=" .. settings.DatabaseName .. "&sortby=rank&offset=0";

local interfaceMngr = nil;
local cbrowser = nil;
local opacs = nil;
local PrimoNewUI_ChromiumSearchForm = {};
PrimoNewUI_ChromiumSearchForm.Form = nil;
cbrowser = nil;
PrimoNewUI_ChromiumSearchForm.RibbonPage = nil;

function Init()
		interfaceMngr = GetInterfaceManager();
		--Create Form
		PrimoNewUI_ChromiumSearchForm.Form = interfaceMngr:CreateForm("PrimoNewUI_Chromium", "Script");
		 -- Create browser
		cbrowser = PrimoNewUI_ChromiumSearchForm.Form:CreateBrowser("PrimoNewUI_Chromium_Search", "PrimoNewUI_Chromium_Search_Browser", "PrimoNewUI_Chromium_Search", "Chromium");
		--cbrowser:ShowDevTools();
		-- Hide the text label
		cbrowser.TextVisible = false;

		-- Since we didn't create a ribbon explicitly before creating our browser, it will have created one using the name we passed the CreateBrowser method.  We can retrieve that one and add our buttons to it.
		PrimoNewUI_ChromiumSearchForm.RibbonPage = PrimoNewUI_ChromiumSearchForm.Form:GetRibbonPage("PrimoNewUI_Chromium_Search");
		-- Imports price from first Item in list.  

	   
    -- Here we are adding a new button to the ribbon
    PrimoNewUI_ChromiumSearchForm.RibbonPage:CreateButton("Search ISxN", GetClientImage("Search32"), "SearchISxN", "Scope: " .. settings.SearchScope);
    PrimoNewUI_ChromiumSearchForm.RibbonPage:CreateButton("Search Title", GetClientImage("Search32"), "SearchTitle", "Scope: " .. settings.SearchScope);
    PrimoNewUI_ChromiumSearchForm.RibbonPage:CreateButton("Phrase Search", GetClientImage("Search32"), "SearchPhrase", "Scope: " .. settings.SearchScope);		
		
		
		if settings.PrimoVE then
		-- For customers on Primo VE, add one button mapped to function InputLocationVE
			PrimoNewUI_ChromiumSearchForm.RibbonPage:CreateButton("Input Location/ Call Number", GetClientImage("Borrowing32"), "InputLocationVE", "Location Info");
		else
		-- For customers not on Primo VE, add two buttons: one to open the mashup source, and a second to import location and call number
			PrimoNewUI_ChromiumSearchForm.RibbonPage:CreateButton("Open Holdings", GetClientImage("Borrowing32"), "OpenMashupSource", "Location Info");
			PrimoNewUI_ChromiumSearchForm.RibbonPage:CreateButton("Input Location/ Call Number", GetClientImage("Borrowing32"), "InputLocation", "Location Info");
		end
		
		PrimoNewUI_ChromiumSearchForm.Form:Show();
		
		  if settings.GoToLandingPage then
    DefaultURL();
  elseif settings.AutoSearchISxN then
    SearchISxN();
  elseif settings.AutoSearchTitle then
    SearchTitle();
  end

end


function DefaultURL()
  cbrowser:Navigate(settings.BaseURL .. "?vid=" .. settings.DatabaseName);
end

-- This function searches for ISxN for both Loan and Article requests.
function SearchISxN()
  if GetFieldValue("Transaction", "ISSN") ~= "" then
  local issn = GetFieldValue("Transaction", "ISSN");
  local stripped_issn = issn:gsub('%D','');
    cbrowser:Navigate(settings.BaseURL .. "?query=any,contains," .. stripped_issn .. "&" .. params);
  else
    interfaceMngr:ShowMessage("ISxN is not available from request form", "Insufficient Information");
  end
end

-- This function performs a quoted phrase search for LoanTitle for Loan requests and PhotoJournalTitle for Article requests.
function SearchPhrase()
  if GetFieldValue("Transaction", "RequestType") == "Loan" then  
    cbrowser:Navigate(settings.BaseURL .. "?query=any,contains,%22" .. GetFieldValue("Transaction", "LoanTitle")  .. "%22&"  .. params);
  elseif GetFieldValue("Transaction", "RequestType") == "Article" then  
    cbrowser:Navigate(settings.BaseURL .. "?query=any,contains,%22" .. GetFieldValue("Transaction", "PhotoJournalTitle")  .. "%22&"  .. params);
  else
    interfaceMngr:ShowMessage("The Title is not available from request form", "Insufficient Information");
  end
end

-- This function performs a standard search for LoanTitle for Loan requests and PhotoJournalTitle for Article requests.
function SearchTitle()
  if GetFieldValue("Transaction", "RequestType") == "Loan" then  
    cbrowser:Navigate(settings.BaseURL .. "?query=any,contains," ..  GetFieldValue("Transaction", "LoanTitle") .. "&" .. params);
  elseif GetFieldValue("Transaction", "RequestType") == "Article" then  
    cbrowser:Navigate(settings.BaseURL .. "?query=any,contains," .. GetFieldValue("Transaction", "PhotoJournalTitle") .. "&" .. params);
  else
    interfaceMngr:ShowMessage("The Title is not available from request form", "Insufficient Information");
  end
end





-- This function populates the call number and location in the detail form with the values from the Alma mashup window for customers not on Primo VE
function InputLocation()

	local tags2 = cbrowser:EvaluateScript("document.getElementsByTagName('form')[0].innerHTML").Result;
	interfaceMngr:ShowMessage("[[" .. tags2 .. "]]", "form results");

					local tags2 = cbrowser:EvaluateScript("document.getElementsByClassName('best-location-library-code locations-link')[0].innerText").Result;
	interfaceMngr:ShowMessage("[[" .. tags2 .. "]]", "Location");
	
	
						local tags2 = cbrowser:EvaluateScript("document.getElementsByClassName('best-location-sub-location locations-link')[0].innerText").Result;
	interfaceMngr:ShowMessage("[[" .. tags2 .. "]]", "Sub Location");
	
						local tags2 = cbrowser:EvaluateScript("document.getElementsByClassName('best-location-delivery locations-link')[0].innerText").Result;
	interfaceMngr:ShowMessage("[[" .. tags2 .. "]]", "Call Number");

	local doctext2 = cbrowser:EvaluateScript("encodeURI(document.getElementsByTagName('prm-search-result-availability-line')[0].innerHTML)").Result; 
interfaceMngr:ShowMessage("[[" .. doctext2 .. "]]", "holdingInfo results");
local library_name = doctext2:match('locations-link">(.-)<');
interfaceMngr:ShowMessage("[[" .. library_name .. "]]", "LibraryName results");

	local tags2 = cbrowser:EvaluateScript("document.getElementsByTagName('html')[1].innerHTML").Result;
		interfaceMngr:ShowMessage("[[" .. tags2 .. "]]", "holdingInfo results");
		
		local tags2 = cbrowser:EvaluateScript("document.getElementsByTagName('iframe')[0].innerHTML").Result;
	interfaceMngr:ShowMessage("[[" .. tags2 .. "]]", "iframe results");
	
			local tags2 = cbrowser:EvaluateScript("document.getElementsByTagName('tbody')[0].textContent").Result;
	interfaceMngr:ShowMessage("[[" .. tags2 .. "]]", "tbody text content");
	
local tags2 = cbrowser:EvaluateScript(10000, "document.getElementsByClassName('nextLine holdingCallNumber')[0].innerHTML").Result;
	interfaceMngr:ShowMessage("[[" .. tags2 .. "]]", "innerHTML");
	
				local tags2 = cbrowser:EvaluateScript("document.getElementsByClassName('itemLocationName')[0]").Result;
	interfaceMngr:ShowMessage("[[" .. tags2 .. "]]", "itemLocationName");
	
	

	
	local library_name = tags2:match('itemLibraryName">(.-)</span>'):gsub('itemLibraryName">', '');
	interfaceMngr:ShowMessage("[[" .. library_name .. "]]", "Items not found");
	
	
local check_for_item = nil;
  -- If selectIssueForm does not exist, this is the search results page. Prompt user to open holdings in the mashup window first.  
  	local check_for_item = cbrowser:EvaluateScript("document.getElementsByClassName('itemLibraryName')[0].textContent").Result;
	interfaceMngr:ShowMessage("[[" .. check_for_item .. "]]", "test");
	if (check_for_item == nil) then
		interfaceMngr:ShowMessage("Open a full record and click the Open Holdings button.", "Open holdings first");
		return false;
	end
	
end
function Infpuntsd()
	
  
  if document:getElementById("selectIssueForm") == nil then
    interfaceMngr:ShowMessage("Open a full record and click the Open Holdings button.", "Open holdings first");
    return false;
  else
    -- If the Location label does not exist, the mashup is showing multiple holdings.
    -- Prompt user to select one first.
    if document:GetElementById("locationLabel") == nil then
      interfaceMngr:ShowMessage("Select a holding to import.", "Multiple holdings found");
      return false;
    else
      -- Loop through all spans on the page. Get info from spans with classes "itemLocationName" and "itemAccessionNumber."
      local spans = document:GetElementsByTagName("span");
      local span = nil;
      local span_class = nil;
      local location_name = nil;
      local call_number = nil;
      for s=0,spans.count-1 do
        span = spans:get_Item(s);
        span_class = span:GetAttribute("className");
        if span_class ~= nil then
          if span_class == "itemLocationName" then
            location_name = span.InnerText;  
          elseif span_class == "itemAccessionNumber" then
            call_number = span.InnerText;
          end
        end
      end
      if (location_name == nil or call_number == nil) then
        interfaceMngr:ShowMessage("Location or call number not found on this page.", "Information not found");
        return false;
      else
        SetFieldValue("Transaction", "Location", location_name);
        SetFieldValue("Transaction", "CallNumber", call_number);
      end
    end
  end
  -- Switch back to Details form.
  ExecuteCommand("SwitchTab", {"Detail"});
end

-- This function populates the call number and location in the detail form for Ex Libris customers on Primo VE
function InputLocationVE()

	local tags = cbrowser:EvaluateScript("document.getElementsByTagName('prm-location-items')[0].innerHTML").Result;
	if (tags == nil) then
		interfaceMngr:ShowMessage("Open a full record with local items available.", "Record with physical holdings required");
	end
  
	local location_name = tags:match('collectionTranslation">(.-)<'):gsub('collectionTranslation">', '');
	interfaceMngr:ShowMessage("[[" .. location_name .. "]]", "Items not found"); 

	local call_number = tags:match('callNumber" dir="auto">(.-)<'):gsub('callNumber" dir="auto">', '');
	interfaceMngr:ShowMessage("[[" .. call_number .. "]]", "Items not found");

		if (location_name == nil or call_number == nil) then
			interfaceMngr:ShowMessage("Location or call number not found on this page.", "Information not found");
			return false;
		else
			SetFieldValue("Transaction", "Location", location_name);
			SetFieldValue("Transaction", "CallNumber", call_number);
		end
	  
		if (settings.AutoSave == true) then
			ExecuteCommand("Save", "Transaction");
		end
	ExecuteCommand("SwitchTab", {"Detail"});
end



