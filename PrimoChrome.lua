-- About PrimoNewUI_Chrome.lua
-- PrimoNewUI_Chromium.lua does an PrimoNewUI_Chromium_Search for the ISBN or Title for loans.
-- scriptActive must be set to true for the script to run.
--
-- 2.1 UPDATE by Andrew Morgan, emeraldflarexii@hotmail.com/Pages/Login
-- Converted to use the Chromium browser.
-- Cleaned up some settings and added a setting to choose which field to import the price.


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
	interfaceMngr:ShowMessage(settings.BaseURL .. "?query=any,contains,%22" .. GetFieldValue("Transaction", "LoanTitle")  .. "%22&"  .. params, "Insufficient Information");
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




-- This function opens the Alma mashup iframe source
function OpenMashupSource()
  local document = cbrowser.WebBrowser.Document;
  -- If selectIssueForm exists, this is the mashup window. Prompt user to click the input button instead.
  if document:getElementById('selectIssueForm') ~= nil then
    interfaceMngr:ShowMessage("Select a holding and click the Input Location/Call Number button.", "Holdings open");
    return false;
  else
	-- If mashup component doesn't exist, prompt user to open a full record.
	local mashups = document:GetElementsByTagName("prm-alma-mashup");
	if (mashups.count == 0) then
      interfaceMngr:ShowMessage("Open a full record.", "Record not selected");
      return false;
    else
      -- Loop through the iframes in the mashup component. If one is the AlmagetitMashupIframe, navigate to the source.
	  local mashup = mashups:get_Item(0);
      local iframes = mashup:getElementsByTagName("iframe");
      local iframe = nil;
      for i=0,iframes.count-1 do
        iframe = iframes:get_Item(i);
        if iframe.Name == "AlmagetitMashupIframe" then
          cbrowser:Navigate(iframe:GetAttribute("src"));
          break
        end
      end
    end
  end
end

-- This function populates the call number and location in the detail form with the values from the Alma mashup window for customers not on Primo VE
function InputLocation()
  local document = cbrowser.WebBrowser.Document;
  -- If selectIssueForm does not exist, this is the search results page. Prompt user to open holdings in the mashup window first.
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
  -- local document = PrimoNewUIForm.Browser.WebBrowser.Document;
   cbrowser:ExecuteScript("alert('Starting')");
  -- local document = cbrowser:ExecuteScript("document.getElementsByTagName('html')[0].innerHTML");
  -- cbrowser:ExecuteScript("alert(" .. document .. ")");
   --local document2 = cbrowser:ExecuteScript("document.getElementsByTagName('html')[0].innerHTML");
   --cbrowser:ExecuteScript("alert(" .. document2 .. ")");
  --local doctext = cbrowser:EvaluateScript("document.documentElement.outerHTML").Result; 
  
 -- cbrowser:ExecuteScript("alert('" .. doctext .. "')");
 -- LogDebug(doctext);
   
--   cbrowser:ExecuteScript("alert('Did 1')");
   
   local doctext2 = cbrowser:EvaluateScript(10000, "document.getElementsByTagName('html')[0].innerHTML").Result; 
 --  local response = cbrowser:EvaluateScript(10000, "document.getElementsByTagName('html')[0].innerHTML");
   local response = cbrowser:EvaluateScript(10000, "document.getElementsByTagName('prm-location-items')[0].innerHTML");   
   if (response.Success) then 
    --Do something with the value returned
		if (response.Result ~= "") then      
		--	atlasAddonAsync.executeAddonFunction('getCallNumber', Result);
		else
			browser:ExecuteScript("alert('Username not set to Addon!')");
		end
	else
		LogDebug(response.Message);
	end
   
 local tags3 = cbrowser:EvaluateScript("var amounts = Array.prototype.slice.call(document.querySelectorAll('span.amount')).map(function(a){ return a.innerHTML; }");
 
   
     --LogDebug(doctext2);
	  interfaceMngr:ShowMessage("[[" .. doctext2 .. "]]", "Items not found");
     cbrowser:ExecuteScript("alert('Did 2')"); 
--	 LogDebug("[[" .. doctext2 .. "]]");
  -- If the OPAC component does not exist, prompt user to open a full record with local availability
 -- opacs = cbrowser:ExecuteScript("document.getElementsByTagName('prm-opac')");
 
 
 -- This one below pulled through the prm-locations
 local tags = cbrowser:EvaluateScript(10000, "document.getElementsByTagName('prm-location-items')[0].innerHTML").Result;
  
-- This gets Schrader Hall!
  local location_name = tags:match('collectionTranslation">(.-)<'):gsub('collectionTranslation">', '');
  
  interfaceMngr:ShowMessage("[[" .. location_name .. "]]", "Items not found"); 
  --local tags = cbrowser:ExecuteScript("document.getElementsByTagName('prm-location-items')[0].innerHTML");
  -- LogDebug("[[" .. tags .. "]]");
  -- interfaceMngr:ShowMessage("[[" .. tags .. "]]", "Items not found");
   --local response = cbrowser:EvaluateScript("tags.match(/<span ng-if='$ctrl.currLoc.location.callNumber' dir='auto'>(.*?)<\/span>/g)");

	local call_number = tags:match('callNumber" dir="auto">(.-)<'):gsub('callNumber" dir="auto">', '');
	 interfaceMngr:ShowMessage("[[" .. call_number .. "]]", "Items not found");
  -- local selected = tags:match('<span ng-if="$ctrl.currLoc.location.callNumber" dir="auto">.</span>'):gsub('<span ng-if="$ctrl.currLoc.location.callNumber" dir="auto">', ''):gsub('</span>', '');
--local selected = string.match(tags, '<span ng-if="$ctrl.currLoc.location.callNumber" dir="auto"> (.-) </span>');
--interfaceMngr:ShowMessage("[[" .. selected .. "]]", "Items not found");

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
   
function getCallNumber(Result)
local lis = Result;

	  -- Loop through all spans and get info based on ng-if and ng-bind-html attributes (no classes or useful IDs in VE)
      local location_items = lis:get_Item(0);
      local spans = location_items:getElementsByTagName("span");
      local span = nil;
      local span_if = nil;
      local span_bind = nil;
      local location_name = nil;
      local call_number = nil;
      for s=0,spans.count-1 do
  	    span = spans:get_Item(s);
        span_bind = span:GetAttribute("ng-bind-html");
		span_if = span:GetAttribute("ng-if");
        if span_bind ~= nil then
          if string.find(span_bind, "collectionTranslation") then
            location_name = span.innerText;
          end
        end
		if span_if ~= nil then
          if string.find(span_if, "callNumber") then
            if span.innerText ~= "" then
              call_number = span.innerText;
            end
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
  

  -- Switch back to Details form.
  ExecuteCommand("SwitchTab", {"Detail"});
end






-- This function populates the call number and location in the detail form for Ex Libris customers on Primo VE
function InputLocationVE2()
interfaceMngr:ShowMessage("You Clicked the button.", "Open holdings first");
 -- local document = cbrowser.Document;
  --interfaceMngr:ShowMessage(document, "Open holdings first");
  -- If the OPAC component does not exist, prompt user to open a full record with local availability
  --local opacs = document:GetElementsByTagName("prm-opac");
  cbrowser:ExecuteScript("alert('Show a javascript popup alert message')");
 end
 function InputLocationVE2()
 local document = cbrowser:ExecuteScript("document.getElementsByTagName('html')[0].innerHTML");
 LogDebug("The document value is: " .. document);
interfaceMngr:ShowMessage(document, "Open holdings first1"); 
--local opacs3 = document:GetElementsByTagName("prm-opac");
  --local opacs =	cbrowser:ExecuteScript("document.GetElementsByTagName('prm-opac')");
  local opacs = document:GetElementsByTagName("prm-opac");
interfaceMngr:ShowMessage(opacs, "Open holdings first2");  
  if opacs.count == 0 then
    interfaceMngr:ShowMessage("Open a full record with local items available.", "Record with physical holdings required");
  return false;
  else
    -- Get items within the OPAC component (not other members)
    local opac = opacs:get_Item(0);
    local lis = opac:getElementsByTagName("prm-location-items");
    if lis.count == 0 then
      interfaceMngr:ShowMessage("No local items found in this record.", "Items not found");
      return false;
    else
	  -- Loop through all spans and get info based on ng-if and ng-bind-html attributes (no classes or useful IDs in VE)
      local location_items = lis:get_Item(0);
      local spans = location_items:getElementsByTagName("span");
      local span = nil;
      local span_if = nil;
      local span_bind = nil;
      local location_name = nil;
      local call_number = nil;
      for s=0,spans.count-1 do
  	    span = spans:get_Item(s);
        span_bind = span:GetAttribute("ng-bind-html");
		span_if = span:GetAttribute("ng-if");
        if span_bind ~= nil then
          if string.find(span_bind, "collectionTranslation") then
            location_name = span.innerText;
          end
        end
		if span_if ~= nil then
          if string.find(span_if, "callNumber") then
            if span.innerText ~= "" then
              call_number = span.innerText;
            end
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
