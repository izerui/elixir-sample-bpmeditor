///////////////////////////////////////////////////////////////////////////////
// Licensed Materials - Property of IBM
// 5724-Y31,5724-Z78
// © Copyright IBM Corporation 2007, 2013. All Rights Reserved.
//
// Note to U.S. Government Users Restricted Rights:
// Use, duplication or disclosure restricted by GSA ADP Schedule
// Contract with IBM Corp.
///////////////////////////////////////////////////////////////////////////////
package
{
  import flash.events.Event;
  import flash.events.HTTPStatusEvent;
  import flash.events.IOErrorEvent;
  import flash.events.ProgressEvent;
  import flash.events.SecurityErrorEvent;
  import flash.net.URLRequest;
  import flash.net.URLStream;
  import flash.utils.ByteArray;
  
  import mx.controls.Alert;
  import mx.core.FlexGlobals;
  import mx.resources.IResourceManager;
  import mx.resources.ResourceManager;
  
  /**
   * This class contains a set of utility methods that can be used in samples.
   */
  public class DemoUtil
  {
    /* For DEBUG when running over http. For instance, the help text of BPMMonitor 
     can be binded to it. 
    [Bindable] 
    public static var debugString:String = "";
    */
    
    /**
     * This method builds an absolute path to the given URL which is relative
     * to the application. To do that, we get the url of the application,
     * remove the application's name from it and finally append the given url.
     * 
     * @param url The URL relative to the application to transform into
     *            an absolute URL.
     * @return The absolute URL.
     */
    public static function getAbsolutePathTo(url:String):String
    {
      var absUrl:String = new String(url);
      
      // get the url of the application
      var s:String = FlexGlobals.topLevelApplication.url;
      
      // get the index of the last / or \ in the application url
      var index:int = Math.max(s.lastIndexOf("\\"), s.lastIndexOf("/"));
      
      // remove the application name from the absolute url and append the relative url
      if (index != -1) absUrl = s.substr(0, index + 1) + url;        
      
      return absUrl;
    }
    
   /**
     * Asynchronously loads a file using the locale-dependent relative path of a fileName 
     * (for instance, en_us/influenza.sbml, ja_JP/project.idpr).
     * 
     * The method iterates over the locales of the localeChain in their order of
     * priority and tries to open a stream using the relative path obtained by 
     * concatenating the locale name and the fileName (with path separator). 
     * If this succeeds, the loadFunction is called with the localized relative 
     * path as argument. Otherwise, it tries the next locale. 
     * 
     * If the file is not found for any of the locales in the locale chain, it
     * falls back to the en_US locale.
     * 
     * This utility is intended for demos that package their data files in directories
     * such as src/data/en_US. It can be used in both cases: when translations in other
     * languages (japanese...) are provided, or only the English variant is provided.
     * In the latter case, this allows for instance a given IBM geographical entity
     * to add a translation without needing to modify the code of the demo. 
     * 
     * Error feedback: an optional errorHandler function taking a String argument can 
     * be passed. If passed, it is called in case the file is not found for any of the 
     * locales including for the en_US fallback locale. For convenience, the fileName 
     * is passed to it.
     * 
     * @param fileName The name of the file to be loaded.
     * @param loadFunction A function taking a String argument. When a file with the
     *    given fileName is found in the localized directory, this function is
     *    called with the localized relative path of the file as argument.
     * @param resourceManager The resource manager. 
     * @param errorHandler An optional function taking a String argument. If this 
     *    argument is passed, the function is called (fileName being passed to it)
     *    if the data file has not been found for any of the locales in the locale
     *    chain, including for the fallback case en_US.
     * @param fallbackToEnUs Optional boolean argument indicating whether
     *    it should try with en_US locale in case not found for any other. 
     * @param fallbackErrorHandler Optional boolean argument. If true, and if 
     *    a custom errorHandler is not passed, a default error handler is used,
     *    which calls Alert.show with a message informing that the given file name
     *    has not been found. If false, and if no custom errorHandler is passed,
     *    the loading fails silently.
     */
    public static function asyncLoadLocalized(fileName:String, 
                                              loadFunction:Function,
                                              resourceManager:IResourceManager,
                                              errorHandler:Function = null,
                                              fallbackToEnUs:Boolean = true,
                                              fallbackErrorHandler:Boolean = true) : void
    {
      /* Elixir 3.0 used to have code such as:
      if (resourceManager.localeChain.indexOf("ja_JP") != -1) {
      return "ja_JP/" + fileName;
      } else {
      return "en_US/" + fileName;
      }
      */
      // On the other side, Elixir Diagram 3.0 used to only have the en_US 
      // data file and the loading code did not care about the locale.
      // To support data files for both ja and en, and at the same time to 
      // ease the addition of other translations, let's try the locales
      // in the localChain one by one.
      
      // debugString = ""; // For debug
      
      var locales:Array = resourceManager.localeChain;
      
      /* For DEBUG. 
      locales = new Array();
      locales.push("hahaHihiNonExistingLocale");
      locales.push("ru_RU");
      locales.push("en_US");
      */
      
      if (locales == null) // does not happen in practice
        locales = new Array();
      
      if (errorHandler == null && fallbackErrorHandler)
        errorHandler = defaultAsyncLoadLocalized;
      
      tryLocalizedRelPath(fileName, loadFunction, locales, 0, errorHandler, fallbackToEnUs);
    }
    
    /**
     * Asynchronously checks whether a file exists with a relative path constructed
     * from the locale with the provided localeCounter in the array of locales.
     * If not found, recursively calls itself with an incremented localeCounter.
     * If file does not exist for any of the locales, the errorHandler function is 
     * called and fileName is passed as argument.
     */
    private static function tryLocalizedRelPath(fileName:String, 
                                                loadFunction:Function,
                                                locales:Array, 
                                                localeCounter:int,
                                                errorHandler:Function = null,
                                                fallbackToEnUs:Boolean = true) : void
    {
      // Some explanations about this code. Testing the behavior of URLStream.load
      // with several browsers (Chrome 11, Firefox 4.0, IE8) has shown different behaviors
      // for each, in particular when attempting to load a non-existant URL. 
      // And for each browser the behavior is different depending on running over http
      // or locally. This code aims to cope with all different behaviors.
      
      if (localeCounter >= locales.length) {
        if (!fallbackToEnUs && errorHandler != null) {
          // the data file has not been found for any of the locales in the
          // locale chain
          errorHandler(fileName);  
        } else if (fallbackToEnUs) {
          // Fallback to en_US locale if not found for any locale in the locale chain.
          // (in case en_US happens to not be already in the locale chain).
          // debug("okay, fallback to en_US");
          loadFunction(getLocalizedRelPath("en_US", fileName));
        }
        // all locales have been checked, error case has been treated, we are done
        return; 
      }
      
      var localizedRelPath:String = getLocalizedRelPath(locales[localeCounter], fileName);
      
      var urlStream:URLStream = new URLStream();

      var progressEventCounter:int = 0; // init
      
      urlStream.addEventListener(Event.OPEN, fileFoundHandler);
      urlStream.addEventListener(ProgressEvent.PROGRESS, fileFoundHandler);
      urlStream.addEventListener(Event.COMPLETE, fileFoundHandler);
      // Necessary for IE8+FP10.3, where we get a "progress" event with bytesAvailable > 0
      // even for a non-existing URL !!!!!......
      // urlStream.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
      urlStream.addEventListener(IOErrorEvent.IO_ERROR, fileNotFoundHandler);
      // Necessary for Chrome 
      urlStream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fileNotFoundHandler);
      
      try {
        // debug("stream.load for " + localizedRelPath);
        urlStream.load(new URLRequest(localizedRelPath));
      } catch (err:*) {
        // debug("exception, calling fileNotFoundHandler");
        fileNotFoundHandlerImpl(urlStream);
      } 
      
      function fileFoundHandler(event:Event) : void {
        var stream:URLStream = event.target as URLStream;
        
        /*
        debug("fileFoundHandler, e.type: " + event.type + 
              " stream.bytesAvailable: " + stream.bytesAvailable + 
              " progressEventCounter: " + progressEventCounter); 
        */
        
        // for complete event we don't need to check anything
        // but we try to not wait until complete, for speed reasons (avoid downloading the entire file)
        if (event.type == ProgressEvent.PROGRESS || event.type == Event.OPEN) {
          var bytesAvailable:uint = stream.bytesAvailable;
          if (bytesAvailable == 0) {
            // At least with IE8+FlashPlayer 10.3, URLStream.load fires
            // an event "open" for a file that does not exist, and fires the
            // error event only after that (while Firefox for instance raises directly
            // the error event). Hence, for IE's sake, we must skip the open event
            // with no bytesAvailable.
            // debug("   skipping, because 0 bytes available");
            return;
          }
        }
        
        if (event.type == ProgressEvent.PROGRESS) {
          /* For DEBUG
          var bytes:ByteArray = new ByteArray();
          stream.readBytes(bytes, 0, bytesAvailable);
          debug("byteArray: " + bytes.toString());
          */
          
          progressEventCounter++;
          if (progressEventCounter == 1) {
            // Skip the first progress event, because with IE(8) we get one progress event 
            // even for an inexisting URL. The bytes available in this casea are:
            // <h1>Page not found: /dojo-diagrammer-oldrepo/src/samples/linkdecorations/bin-debug/hahaHihi/ApplicationProcess.idfl</h1>
            // (but this can vary according to servers).
            // debug("   skipping, because it's the first event of type progress so unreliable (IE8 case)");
            return; 
          }
        }
        
        // debug("  okay, now fileFoundHandler calls loadFunction for " + localizedRelPath);
        if (stream) {
          try {
            stream.close();
          } catch (err:*) { 
          }
        }
        loadFunction(localizedRelPath);
      }
      
      function fileFoundHandlerImpl(locRelPath:String, stream:URLStream) : void {
        // debug("fileFoundHandlerImpl calls loadFunction for " + localizedRelPath + " stream: " + stream);
        if (stream) {
          try {
            stream.close();
          } catch (err:*) { 
          }
        }
        loadFunction(locRelPath);
      }
      
      function fileNotFoundHandler(event:Event) : void {
        // debug("fileNotFoundHandler for " + localizedRelPath + ", launching tryLocalizedRelPath for next locale");
        var stream:URLStream = event.target as URLStream;
        fileNotFoundHandlerImpl(stream);
      }
      
      function fileNotFoundHandlerImpl(stream:URLStream) : void {
        // debug("fileNotFoundHandler for " + localizedRelPath + ", launching tryLocalizedRelPath for next locale");
        if (stream) {
          try {
            stream.close();
          } catch (err:*) { 
            // In some cases (Chrome 11), urlStream.load throws an exception when 
            // the file is not found, and trying to close the stream throws itself 
            // another exception. Hence the silent catch.
          }
        }
        tryLocalizedRelPath(fileName, loadFunction, locales, localeCounter + 1, errorHandler, fallbackToEnUs);
      }
      
      function httpStatusHandler(event:HTTPStatusEvent):void {
        // debug("httpStatusHandler, status: " + event.status);
        var stream:URLStream = event.target as URLStream;
        // Note that depending on browser, FlashPlayer may not be able to provide the correct status
        // and provides instead the value 0.
        // See Adobe bug FP-721 "URLLoader - HttpStatusEvent should return a valid http status code and not 0"
        if (event.status >= 400) {
          // >= 400 includes "4xx Client Error" and (probably useless in practice) "5xx Server Error".
          // debug(" httpStatusHandler calls fileNotFoundHandler");
          fileNotFoundHandlerImpl(stream); 
        }
      }
    }
    
    /* For DEBUG
    private static function debug(str:String) : void
    {
      trace(str);
      debugString += (str + "\n");
    }
    */
    
    /**
     * Constructs the localized relative path of a given fileName.
     */
    private static function getLocalizedRelPath(locale:String, fileName:String) : String 
    {
      return locale + "/" + fileName;
    }
    
    private static function defaultAsyncLoadLocalized(fileName:String) : void
    {
      Alert.show(ResourceManager.getInstance().getString("elixirsamplebar_enterprise", "demoutil.fileNotFound", [fileName]));
    }
  }
}
