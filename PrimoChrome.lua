-- About PrimoNewUI_Chromium.lua
--
-- Author: Bill Jones III, SUNY Geneseo, jonesw@geneseo.edu
-- Based on methods developed by Tamara Marnell, Central Oregon Community College, libsys@cocc.edu (2020-02-11)
-- PrimoNewUI_Chromium.lua provides a basic search for ISBN, ISSN, Title, and Phrase Searching for the Primo New UI interface.
-- There is a config file that is associated with this Addon that needs to be set up in order for the Addon to work.
-- Please see the ReadMe.txt file for example configuration values that you can pull from your Primo New UI URL.
--
-- IMPORTANT:  One of the following settings must be set to true in order for the Addon to work:
-- set GoToLandingPage to true for this script to automatically navigate to your instance of Primo New UI.
-- set AutoSearchISxN to true if you would like the Addon to automatically search for the ISxN.
-- set AutoSearchTitle to true if you would like the Addon to automatically search for the Title.


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
	-- Create Chromium browser
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

function OpenMashupSource()
	--local iframe_src = cbrowser:EvaluateScript("document.getElementsByTagName('iframe')[0].getAttribute('src');").Result;
	iframe_src = cbrowser:EvaluateScript("document.getElementsByName('AlmagetitMashupIframe')[0].getAttribute('src');").Result;
	--interfaceMngr:ShowMessage("[[" .. iframe_src .. "]]", "Location");
	--interfaceMngr:ShowMessage(string.sub(iframe_src, 1, 5), "URL cutter");
	
	--the line below checks to see if the URL contains https.  If it does not, then the iFrame link is from the search results.  If it does contain https, it is from the record item view.
	--Note: sometimes the page needs to be refreshed on the open record before it captures the https
	if iframe_src == nil then
		interfaceMngr:ShowMessage("Open a full record with local items available.  If the full record is open, please click Refresh in the top ribbon.", "Record with physical holdings required");	
	else
		local https_checker = string.sub(iframe_src, 1, 5);
		if (iframe_src == nil or https_checker ~= 'https') then
			interfaceMngr:ShowMessage("Open a full record with local items available.  If the full record is open, please click Refresh in the top ribbon.", "Record with physical holdings required");
		else
		cbrowser:Navigate(iframe_src);
		end
	end
end

function InputLocation()

local iframe_checker = cbrowser:EvaluateScript("document.getElementsByTagName('form')[0].getAttribute('id');").Result;
	--interfaceMngr:ShowMessage("[[" .. iframe_checker .. "]]", "Location");
	if (iframe_checker ~= 'selectIssueForm') then
		interfaceMngr:ShowMessage("Open a full record with local items available.", "Record with physical holdings required");
		return false;
	else

		local single_location_checker = cbrowser:EvaluateScript("document.getElementsByTagName('li')[2].getAttribute('id');").Result;
		--interfaceMngr:ShowMessage(single_location_checker, "Multiple holdings found");
		if (single_location_checker ~= 'locationLabel') then
			interfaceMngr:ShowMessage("Select a holding to import.", "Multiple holdings found");
			return false;
		else	
			local library_text = cbrowser:EvaluateScript("document.getElementsByClassName('libraryName itemLibraryName')[0].innerText").Result;
			--interfaceMngr:ShowMessage("[[" .. library_text .. "]]", "Library Name");
	
			local library_sub_text = cbrowser:EvaluateScript("document.getElementsByClassName('itemLocationName')[0].innerText").Result;
			--interfaceMngr:ShowMessage("[[" .. library_sub_text .. "]]", "Library Sub Location");
	
			local call_number_text = cbrowser:EvaluateScript("document.getElementsByClassName('itemAccessionNumber')[0].innerText").Result;
			--interfaceMngr:ShowMessage("[[" .. call_number_text .. "]]", "Call Number");
	
			if (library_text == nil or call_number_text == nil) then
				interfaceMngr:ShowMessage("Location or call number not found on this page.  Be sure to open an item record to import location and call number.", "Information not found");
				return false;
			else
				SetFieldValue("Transaction", "Location", library_text .. " " .. library_sub_text);
				SetFieldValue("Transaction", "CallNumber", call_number_text);
			end
		end
		ExecuteCommand("SwitchTab", {"Detail"});	
	end
end

-- This function populates the call number and location in the detail form for Ex Libris customers on Primo VE
function InputLocationVE()

	local tags = cbrowser:EvaluateScript("document.getElementsByTagName('prm-location-items')[0].innerHTML").Result;
	if (tags == nil) then
		interfaceMngr:ShowMessage("Open a full record with local items available.", "Record with physical holdings required");
	end
  
	local location_name = tags:match('collectionTranslation">(.-)<'):gsub('collectionTranslation">', '');
	--interfaceMngr:ShowMessage("[[" .. location_name .. "]]", "Items not found"); 

	local call_number = tags:match('callNumber" dir="auto">(.-)<'):gsub('callNumber" dir="auto">', '');
	--interfaceMngr:ShowMessage("[[" .. call_number .. "]]", "Items not found");

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
