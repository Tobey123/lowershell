Add-Type @'

using System;
using System.Reflection;
using System.Runtime.InteropServices.ComTypes;

public class CacheReader
{
  [System.Runtime.InteropServices.DllImport("Wininet.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
  public static extern Boolean GetUrlCacheEntryInfo(String lpxaUrlName, IntPtr lpCacheEntryInfo, ref int lpdwCacheEntryInfoBufferSize);

  struct LPINTERNET_CACHE_ENTRY_INFO {
    #pragma warning disable 0649
    public int dwStructSize;
    public IntPtr lpszSourceUrlName;
    public IntPtr lpszLocalFileName;
    public int CacheEntryType;
    public int dwUseCount;
    public int dwHitRate;
    public int dwSizeLow;
    public int dwSizeHigh;
    public FILETIME LastModifiedTime;
    public FILETIME Expiretime;
    public FILETIME LastAccessTime;
    public FILETIME LastSyncTime;
    public IntPtr lpHeaderInfo;
    public int dwheaderInfoSize;
    public IntPtr lpszFileExtension;
    public int dwEemptDelta;
    #pragma warning restore 0649
  }

  const int ERROR_FILE_NOT_FOUND = 0x2;

  public static string GetPathForCachedFile(string fileUrl) {
    int cacheEntryInfoBufferSize = 0;
    IntPtr cacheEntryInfoBuffer = IntPtr.Zero;
    int lastError;
    Boolean result;
    try {
      result = GetUrlCacheEntryInfo(fileUrl, IntPtr.Zero, ref cacheEntryInfoBufferSize);
      lastError = System.Runtime.InteropServices.Marshal.GetLastWin32Error();
      if (result == false) {
        if (lastError == ERROR_FILE_NOT_FOUND) return null;
      }
      cacheEntryInfoBuffer = System.Runtime.InteropServices.Marshal.AllocHGlobal(cacheEntryInfoBufferSize);

      result = GetUrlCacheEntryInfo(fileUrl, cacheEntryInfoBuffer, ref cacheEntryInfoBufferSize);
      lastError = System.Runtime.InteropServices.Marshal.GetLastWin32Error();
      if (result == true) {
        Object strObj = System.Runtime.InteropServices.Marshal.PtrToStructure(cacheEntryInfoBuffer, typeof(LPINTERNET_CACHE_ENTRY_INFO));
        LPINTERNET_CACHE_ENTRY_INFO internetCacheEntry = (LPINTERNET_CACHE_ENTRY_INFO) strObj;
        String localFileName = System.Runtime.InteropServices.Marshal.PtrToStringAuto(internetCacheEntry.lpszLocalFileName);
        return localFileName;
      } else {
        return null;
      }
    } finally {
      if (!cacheEntryInfoBuffer.Equals(IntPtr.Zero))
        System.Runtime.InteropServices.Marshal.FreeHGlobal(cacheEntryInfoBuffer);
    }
  }

}

'@

$url = "http://www.lofter.com/tag/%E9%94%9F%E6%96%A4%E6%8B%B7%E9%94%9F%E6%96%A4%E6%8B%B7%E9%94%9F%E6%96%A4%E6%8B%B7%E9%94%9F%E6%96%A4%E6%8B%B7"

$ie = New-Object -comobject InternetExplorer.Application -property @{navigate2=$url; visible = $false}
while ($ie.Busy -eq $true) { Start-Sleep -Milliseconds 500; }  
$images = $ie.document.getElementsByTagName('img') | where {$_.outerhtml -like '*data-origin*'} | % {$_.src -replace '\?imageView.*$'}