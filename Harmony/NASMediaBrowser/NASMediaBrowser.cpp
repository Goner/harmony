 //
//  NASMediaBrowser.cpp
//  


#include "NASMediaBrowser.h"
#include "PltDidl.h"
#include "PltUtilities.h"

#include "interfaceudt_client.h"
#include "remote_auth.h"
#include "cJSON.h"

const char* NASDeviceID = "996d6572-0000-0000-004009901099";
const char* NASServiceType = "urn:schemas-upnp-org:service:ContentDirectory:1";

MediaBrowserEx::MediaBrowserEx(const char*                        uuid,
                               PLT_CtrlPointReference&            ctrlPoint,
                               bool                               use_cache /*= false*/)
    :PLT_SyncMediaBrowser(ctrlPoint, use_cache, NULL),
    deviceID(uuid)
{
}

NPT_Result
MediaBrowserEx::OnDeviceAdded(PLT_DeviceDataReference& device)
{
    NPT_Result ret = PLT_SyncMediaBrowser::OnDeviceAdded(device);
    if(ret == NPT_SUCCESS && device->GetUUID().CompareN(deviceID, deviceID.GetLength(), true) == 0) {
        mediaDevice = device;
        shared_var.SetValue(1);
    }
    return ret;
}

NPT_Result
MediaBrowserEx::WaitForDeviceDiscover()
{
    return shared_var.WaitUntilEquals(1, 30000);
}


NASLocalMediaBrowser::NASLocalMediaBrowser()
    :ctrlPoint(new PLT_CtrlPoint(NULL)),
     mediaBrowser(NASDeviceID, ctrlPoint)
{
    upnp.AddCtrlPoint(ctrlPoint);
}

NPT_Result
NASLocalMediaBrowser::Connect()
{
    upnp.Start();
    ctrlPoint->Discover(NPT_HttpUrl("239.255.255.250", 1900, "*"), "upnp:rootdevice", 1, .0);
    ctrlPoint->Search(NPT_HttpUrl("239.255.255.250", 1900, "*"),
                      "upnp:rootdevice", 2, 100., NPT_TimeInterval(10.));
    NPT_Result ret = mediaBrowser.WaitForDeviceDiscover();
    if(ret != NPT_SUCCESS)
        upnp.Stop();
    return ret;
}
 
NPT_Result
NASLocalMediaBrowser::Browser(const char*  obj_id,
                                         PLT_MediaObjectListReference& list,
                                         NPT_Int32                     start /*= 0*/,
                                         NPT_Cardinal                  max_results /*= 0*/)
{
    return mediaBrowser.BrowseSync(mediaBrowser.GetNASDevice(), obj_id, list, false, start, max_results);
}

NPT_String
NASLocalMediaBrowser::GetIpAddress() {
    NPT_String localIP = mediaBrowser.GetNASDevice()->GetLocalIP().ToString();
    return mediaBrowser.GetNASDevice()->GetDescriptionHost();
}

NASRemoteMediaBrowser::NASRemoteMediaBrowser(const char* account,
                                             const char* password,
                                             const char* license)
    :_account(account),
    _password(password),
    _license(license)

{
}

NPT_Result
NASRemoteMediaBrowser::Connect()
{
    int ret = remote_auth(_account, _password);
    return ret != -1 ? NPT_SUCCESS : NPT_FAILURE;
}

NPT_Result
NASRemoteMediaBrowser::Browser(const char*                      obj_id,
                               PLT_MediaObjectListReference&    list,
                               NPT_Int32                        start /*= 0*/,
                               NPT_Cardinal                     max_results /*= 0*/)
{
    NPT_Int32 index = start;
    do {
        Arguments arguments = SetActionArguments(obj_id, index, 16);
        NPT_String soapRequest;
        FormatSoapRequest(NASServiceType, "Browser", arguments, soapRequest);
        
        cJSON* requestJSONObj = cJSON_CreateObject();
        cJSON_AddStringToObject(requestJSONObj,"METHOD", "UDTACTION");
        cJSON_AddStringToObject(requestJSONObj,"HTTPSOAP", soapRequest);
        char* requestStr = cJSON_Print(requestJSONObj);
        const char* resultStr = transact_proc_call(requestStr);
        cJSON_Delete(requestJSONObj);
        if(*resultStr == '\0') {
            return NPT_FAILURE;
        }
        cJSON* resultJSONObj = cJSON_Parse(resultStr);
        free((void*)resultStr);
        if(strcmp(resultJSONObj->child->valuestring, "SUCCESS")) {
            return NPT_FAILURE;
        }
        const char* soapResponse = resultJSONObj->child->next->valuestring;
        ParseSoapResponse(soapResponse, NASServiceType, "Browser", arguments);
        cJSON_Delete(resultJSONObj);
        
        NPT_Int32 tm = 0;
        arguments["TotalMatches"].ToInteger(tm);
        PLT_MediaObjectListReference items;
        PLT_Didl::FromDidl(arguments["Result"], items);
        
        if (list.IsNull()) {
            list = items;
        } else {
            list->Add(*items);
            items->Clear();
        }
        
        if ((tm && tm <= list->GetItemCount()) || (max_results && max_results <= list->GetItemCount())) {
            break;
        }
        
        index = start + list->GetItemCount();
        printf("start:%d, index:%d\n", start, index);
        
    } while (1);

    return NPT_SUCCESS;
}

Arguments NASRemoteMediaBrowser::SetActionArguments(const char*     obj_id,
                                                    NPT_Int32       start,
                                                    NPT_Cardinal    max_results)
{
    Arguments arguments;
    arguments["ObjectID"] = obj_id;
    arguments["BrowseFlag"] = "BrowseDirectChildren";
    arguments["Filter"] = "*";
    arguments["StartingIndex"] = NPT_String::FromInteger(start);
    arguments["RequestedCount"] =  NPT_String::FromInteger(max_results);
    arguments["SortCriteria"] = "";
    
    return arguments;
}

NPT_Result
NASRemoteMediaBrowser::FormatSoapRequest(const char*        actionName,
                                         const char*        serviceType,
                                         const Arguments&   arguments,
                                         NPT_String&        soapRequest)
{
    NPT_Result res;
    NPT_XmlElementNode* body = NULL;
    NPT_XmlElementNode* request = NULL;
    NPT_XmlElementNode* envelope = new NPT_XmlElementNode("s", "Envelope");
    
    NPT_CHECK_LABEL_SEVERE(res = envelope->SetNamespaceUri("s", "http://schemas.xmlsoap.org/soap/envelope/"), cleanup);
    NPT_CHECK_LABEL_SEVERE(res = envelope->SetAttribute("s", "encodingStyle", "http://schemas.xmlsoap.org/soap/encoding/"), cleanup);
    
    body = new NPT_XmlElementNode("s", "Body");
    NPT_CHECK_LABEL_SEVERE(res = envelope->AddChild(body), cleanup);
    
    request = new NPT_XmlElementNode("u", actionName);
    NPT_CHECK_LABEL_SEVERE(res = request->SetNamespaceUri("u", serviceType), cleanup);
    NPT_CHECK_LABEL_SEVERE(res = body->AddChild(request), cleanup);
    
    for(auto iter = arguments.begin(); iter != arguments.end(); iter++) {
        NPT_CHECK_LABEL_SEVERE(res = PLT_XmlHelper::AddChildText(
                                                                 request,
                                                                 iter->first,
                                                                 iter->second), cleanup);
        
    }
    
    NPT_CHECK_LABEL_SEVERE(res = PLT_XmlHelper::Serialize(*envelope, soapRequest), cleanup);
    delete envelope;
    
    return NPT_SUCCESS;
    
cleanup:
    delete envelope;
    return res;
}

NPT_Result
NASRemoteMediaBrowser::ParseSoapResponse(const char*  soapResponse,
                                         const char*  serviceType,
                                         const char*  actionName,
                                         Arguments&    arguments)
{
    NPT_Result          res;
    NPT_String          service_type;
    NPT_String          str;
    NPT_XmlElementNode* xml = NULL;
    NPT_String          soap_action_name;
    NPT_XmlElementNode* soap_action_response;
    NPT_XmlElementNode* soap_body;
    NPT_XmlElementNode* fault;
    const NPT_String*   attr = NULL;
    
    NPT_LOG_FINER("Reading/Parsing Action Response Body...");
    if (NPT_FAILED(PLT_XmlHelper::Parse(NPT_String(soapResponse), xml))) 
        goto failure;

    
    NPT_LOG_FINER("Analyzing Action Response Body...");
    
    // read envelope
    if (xml->GetTag().Compare("Envelope", true))
        goto failure;
    
    // check namespace
    if (!xml->GetNamespace() || xml->GetNamespace()->Compare("http://schemas.xmlsoap.org/soap/envelope/"))
        goto failure;
    
    // check encoding
    attr = xml->GetAttribute("encodingStyle", "http://schemas.xmlsoap.org/soap/envelope/");
    if (!attr || attr->Compare("http://schemas.xmlsoap.org/soap/encoding/"))
        goto failure;
    
    // read action
    soap_body = PLT_XmlHelper::GetChild(xml, "Body");
    if (soap_body == NULL)
        goto failure;
    
    // check if an error occurred
    fault = PLT_XmlHelper::GetChild(soap_body, "Fault");
    if (fault != NULL) {
        // we have an error
        //        ParseFault(action, fault);
        goto failure;
    }
    
    if (NPT_FAILED(PLT_XmlHelper::GetChild(soap_body, soap_action_response)))
        goto failure;
    
    // verify action name is identical to SOAPACTION header
    if (!soap_action_response->GetTag().Compare(NPT_String(actionName) + "Response", true))
        goto failure;
    
    // verify namespace
    if (!soap_action_response->GetNamespace() ||
        soap_action_response->GetNamespace()->Compare(serviceType))
        goto failure;
    
    // read all the arguments if any
    for (NPT_List<NPT_XmlNode*>::Iterator args = soap_action_response->GetChildren().GetFirstItem();
         args;
         args++) {
        NPT_XmlElementNode* child = (*args)->AsElementNode();
        if (!child) continue;
        
        arguments[child->GetTag()] = child->GetText()?*child->GetText():"";
    }

    goto cleanup;
    
failure:
    // override res with failure if necessary
    if (NPT_SUCCEEDED(res)) res = NPT_FAILURE;
    // fallthrough
    
cleanup:
    
    delete xml;
    return res;
}
