-- About PrimoVE_Chromium.lua
--
-- Author: Bill Jones III, SUNY Geneseo, jonesw@geneseo.edu and Tamara Marnell, Orbis Cascade Alliance, tmarnell@orbiscascade.org
-- PrimoVE_Chromium.lua provides a basic search for ISBN, ISSN, Title, Phrase, and OCLC Number Searching for the Primo VE interface.
-- There is a config file that is associated with this Addon that needs to be set up in order for the Addon to work.
-- Please see the ReadMe.txt file for example configuration values that you can pull from your Primo New UI URL.
--
-- IMPORTANT:  One of the following settings must be set to true in order for the Addon to work:
-- set GoToLandingPage to true for this script to automatically navigate to your instance of Primo New UI.
-- set AutoSearchISxN to true if you would like the Addon to automatically search for the ISxN.
-- set AutoSearchTitle to true if you would like the Addon to automatically search for the Title.k

local settings = {};
settings.GoToLandingPage = GetSetting("GoToLandingPage");
settings.AutoSearchISxN = GetSetting("AutoSearchISxN");
settings.AutoSearchTitle = GetSetting("AutoSearchTitle");
settings.PrimoVE = GetSetting("PrimoVE");
settings.BaseURL = GetSetting("BaseURL");
settings.BarcodeLocation = GetSetting("BarcodeLocation");
settings.DatabaseName = GetSetting("DatabaseName");
settings.SearchTab = GetSetting("SearchTab");
settings.SearchScope = GetSetting("SearchScope");
settings.MaterialTypePhrase = GetSetting("MaterialTypePhrase");
settings.Include_Main_Location_Name = GetSetting("Include_Main_Location_Name");

local params = "tab=" .. settings.SearchTab .. "&search_scope=" .. settings.SearchScope .. "&vid=" .. settings.DatabaseName .. "&sortby=rank&offset=0";

local interfaceMngr = nil;
local cbrowser = nil;
local opacs = nil;
local PrimoVE_ChromiumSearchForm = {};
PrimoVE_ChromiumSearchForm.Form = nil;
cbrowser = nil;
PrimoVE_ChromiumSearchForm.RibbonPage = nil;

function Init()
	interfaceMngr = GetInterfaceManager();
	--Create Form
	PrimoVE_ChromiumSearchForm.Form = interfaceMngr:CreateForm("Primo VE Chromium", "Script");
	-- Create Chromium/WebView2 browser
	local browserType;
	if AddonInfo.Browsers and AddonInfo.Browsers.WebView2 and AddonInfo.Browsers.WebView2 then
		browserType = "WebView2";
	else
		browserType = "Chromium";
	end
	cbrowser = PrimoVE_ChromiumSearchForm.Form:CreateBrowser("PrimoVE_Chromium_Search", "PrimoVE_Chromium_Search_Browser", "PrimoVE_Chromium_Search", browserType);

	--cbrowser:ShowDevTools();
	-- Hide the text label
	cbrowser.TextVisible = false;

	-- Since we didn't create a ribbon explicitly before creating our browser, it will have created one using the name we passed the CreateBrowser method.  We can retrieve that one and add our buttons to it.
	PrimoVE_ChromiumSearchForm.RibbonPage = PrimoVE_ChromiumSearchForm.Form:GetRibbonPage("PrimoVE_Chromium_Search");
	   
	-- Here we are adding a new button to the ribbon
	PrimoVE_ChromiumSearchForm.RibbonPage:CreateButton("Search ISxN", GetClientImage("Search32"), "SearchISxN", "Scope: " .. settings.SearchScope);
	PrimoVE_ChromiumSearchForm.RibbonPage:CreateButton("Search Title", GetClientImage("Search32"), "SearchTitle", "Scope: " .. settings.SearchScope);
	PrimoVE_ChromiumSearchForm.RibbonPage:CreateButton("Phrase Search", GetClientImage("Search32"), "SearchPhrase", "Scope: " .. settings.SearchScope);				
	PrimoVE_ChromiumSearchForm.RibbonPage:CreateButton("OCLC# Search", GetClientImage("Search32"), "SearchOCLC", "Scope: " .. settings.SearchScope);
	
    PrimoVE_ChromiumSearchForm.RibbonPage:CreateButton("Input Location/ Call Number", GetClientImage("Borrowing32"), "InputLocationVE", "Location Info");
		
	PrimoVE_ChromiumSearchForm.Form:Show();
		
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
		cbrowser:Navigate(settings.BaseURL .. "?query=any,contains," .. issn .. "&" .. params);
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


-- This function searches for OCLC for both Loan and Article requests.
function SearchOCLC()
	if GetFieldValue("Transaction", "ESPNumber") ~= "" then
		local oclc_number = GetFieldValue("Transaction", "ESPNumber");
		cbrowser:Navigate(settings.BaseURL .. "?query=any,contains," .. oclc_number .. "&" .. params);
	else
		interfaceMngr:ShowMessage("OCLC Number is not available from request form", "Insufficient Information");
	end
end

-- This function populates the call number and location in the detail form for Ex Libris customers on Primo VE
function InputLocationVE()

	local tags = cbrowser:EvaluateScript("document.getElementsByTagName('prm-location-items')[0].innerHTML").Result;
	--interfaceMngr:ShowMessage("[[" .. tags .. "]]", "HTML Stuff");	
	if (tags == nil) then
		interfaceMngr:ShowMessage("Open a full record with local items available.", "Record with physical holdings required");
	end
	
	-- This if statement makes sure that we have an "Item in Place" details box open on the item record by looking for the characters "Format:"
	if (tags:match(settings.MaterialTypePhrase .. ': (.-)<') ~= nil) then
  
		local location_name = tags:match('ctrl.currLoc.location(.-)<'):gsub('(.-)>', '');
		--interfaceMngr:ShowMessage("[[" .. location_name .. "]]", "Items found"); 
	
		local sublocation_name = tags:match('ctrl.getSubLibraryName(.-)<'):gsub('(.-)>', '');
		--interfaceMngr:ShowMessage("[[" .. sublocation_name .. "]]", "Items found"); 	
	
		local call_number = tags:match('ctrl.currLoc.location.callNumber" dir="auto">(.-)<'):gsub('(.-)>', '');
		--interfaceMngr:ShowMessage("[[" .. call_number .. "]]", "Items not found");

		if (location_name == nil or call_number == nil) then
			interfaceMngr:ShowMessage("Location or call number not found on this page.", "Information not found");
			return false;
		else
		    if(settings.Include_Main_Location_Name) then
			SetFieldValue("Transaction", "Location", location_name .. " " .. sublocation_name);
			else 
			SetFieldValue("Transaction", "Location", sublocation_name);
			end
			SetFieldValue("Transaction", "CallNumber", call_number);
		end
		-- decide if settings.BarcodeLocation is not empty and them copy barcode_text over into ILLiad field	
	    if (settings.BarcodeLocation ~= nil and settings.BarcodeLocation ~= "") then
			local barcode_text1 = tags:match('Barcode: (.-)<');
			if barcode_text1 ~= nil then
				local barcode_text2 = barcode_text1:gsub('Barcode: ', '');
				-- remove any none alphanumeric characters from barcode_text
				local barcode_text2 = string.gsub(barcode_text2, "[^%w]", "");
				--interfaceMngr:ShowMessage("[[" .. barcode_text2 .. "]]", "Barcode Available");
				SetFieldValue("Transaction", settings.BarcodeLocation, barcode_text2);
			else
                interfaceMngr:ShowMessage("No Barcode available. Please select an 'Item in Place' record.", "No Barcode Available"); 
				return false;
			end			
		end
	    ExecuteCommand("SwitchTab", {"Detail"});
	else
	    interfaceMngr:ShowMessage("Please select an 'Item in Place' record.", "Please click on an 'Item in Place' box!");
        return false;
	end
end
