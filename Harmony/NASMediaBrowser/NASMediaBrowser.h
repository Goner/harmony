//
//  NASMediaBrowser.h
//  


#ifndef ____NASMediaBrowser__
#define ____NASMediaBrowser__

#include <map>
#include <memory>

#include "NptStrings.h"
#include "NptTypes.h"
#include "PltMediaItem.h"
#include "PltUPnP.h"
#include "PltCtrlPoint.h"
#include "PltDeviceData.h"
#include "PltSyncMediaBrowser.h"



typedef std::map<NPT_String, NPT_String> Arguments;

class MediaBrowserEx : public PLT_SyncMediaBrowser {
public:
    MediaBrowserEx(const char*                        uuid,
                   PLT_CtrlPointReference&            ctrlPoint,
                   bool                               use_cache = false);
    virtual bool OnMSAdded(PLT_DeviceDataReference& /* device */) { return false; }
    virtual NPT_Result OnDeviceAdded(PLT_DeviceDataReference& device);
    NPT_Result WaitForDeviceDiscover();
    PLT_DeviceDataReference& GetNASDevice() {
        return mediaDevice;
    }

private:
    NPT_String deviceID;
    PLT_DeviceDataReference mediaDevice;
    NPT_SharedVariable shared_var;
};

class NASMediaBrowser  {
public:
    virtual NPT_Result Connect() = 0;
    virtual NPT_Result Browser(const char*  obj_id,
                               PLT_MediaObjectListReference& list,
                               NPT_Int32                     start = 0,
                               NPT_Cardinal                  max_results = 0) = 0;
};


class NASLocalMediaBrowser : public NASMediaBrowser
{
public:
    NASLocalMediaBrowser();
    NPT_Result Connect();
    NPT_Result Browser(const char*  obj_id,
                               PLT_MediaObjectListReference& list,
                               NPT_Int32                     start = 0,
                               NPT_Cardinal                  max_results = 0);
public:
    NPT_String GetIpAddress();

private:
    PLT_UPnP upnp;
    PLT_CtrlPointReference ctrlPoint;
    MediaBrowserEx mediaBrowser;
};

class NASRemoteMediaBrowser : public NASMediaBrowser
{
public:
    NASRemoteMediaBrowser(const char* account,
                          const char* password,
                          const char* license);
    NPT_Result Connect();
    NPT_Result Browser(const char*  obj_id,
                       PLT_MediaObjectListReference& list,
                       NPT_Int32                     start = 0,
                       NPT_Cardinal                  max_results = 0);
private:
    NPT_Result FormatSoapRequest(const char*        actionName,
                                 const char*        serviceType,
                                 const Arguments&   arguments,
                                 NPT_String&        soapRequest);
    NPT_Result ParseSoapResponse(const char*  soapResponse,
                                 const char*  serviceType,
                                 const char*  actionName,
                                 Arguments&    arguments);
    Arguments SetActionArguments(const char*     obj_id,
                            NPT_Int32       start,
                            NPT_Cardinal    max_results);
private:
    NPT_String _account;
    NPT_String _password;
    NPT_String _license;
};

#endif /* defined(____NASMediaBrowser__) */
