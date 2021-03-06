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
    NASMediaBrowser(const char* account, const char* password):_account(account),_password(password){};
    virtual NPT_Result Connect() = 0;
    virtual NPT_Result Reconnect() = 0;
    virtual void Close() = 0;
    virtual NPT_Result Browser(const char*  obj_id,
                               PLT_MediaObjectListReference& list,
                               NPT_Int32                     start = 0,
                               NPT_Cardinal                  max_results = 0) = 0;
    virtual NPT_String GetIpAddress() = 0;
protected:
    NPT_String _account;
    NPT_String _password;
};


class NASLocalMediaBrowser : public NASMediaBrowser
{
public:
    NASLocalMediaBrowser(const char* account, const char* password);
    NPT_Result Connect();
    NPT_Result Reconnect();
    void Close();
    NPT_Result Browser(const char*  obj_id,
                               PLT_MediaObjectListReference& list,
                               NPT_Int32                     start = 0,
                               NPT_Cardinal                  max_results = 0);
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
                          const char* password);
    NPT_Result Connect();
    NPT_Result Reconnect();
    void Close();
    NPT_Result Browser(const char*  obj_id,
                       PLT_MediaObjectListReference& list,
                       NPT_Int32                     start = 0,
                       NPT_Cardinal                  max_results = 0);
    NPT_String GetIpAddress() {return _ipAddress;}
private:
    NPT_Result FormatSoapRequest(const char*        serviceType,
                                 const char*        actionName,
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
    NPT_String _ipAddress;
 
};

#endif /* defined(____NASMediaBrowser__) */
