
-- an interesting possibility to do the windows version entirely in luajit
-- @see http://pastebin.com/XAyU1srh


package.preload['extern.mswindows'] = function()

  local bit = require 'bit'
  local ffi = require 'ffi'
  
  ffi.cdef [[
  
    typedef int32_t bool32;
    typedef intptr_t (__stdcall *WNDPROC)(void* hwnd, unsigned int message, uintptr_t wparam, intptr_t lparam);
    
    enum {
      CS_VREDRAW = 0x0001,
      CS_HREDRAW = 0x0002,
      WM_DESTROY = 0x0002,
      WM_QUIT = 0x0012,
      WS_OVERLAPPEDWINDOW = 0x00CF0000,
      WAIT_OBJECT_0 = 0x00000000,
      PM_REMOVE = 0x0001,
      SW_SHOW = 5,
      INFINITE =  0xFFFFFFFF,
      QS_ALLEVENTS = 0x04BF
    };
    
    typedef struct RECT { int32_t left, top, right, bottom; } RECT;
    typedef struct POINT { int32_t x, y; } POINT;
    
    typedef struct WNDCLASSEXA {
      uint32_t cbSize, style;
      WNDPROC lpfnWndProc;
      int32_t cbClsExtra, cbWndExtra;
      void* hInstance;
      void* hIcon;
      void* hCursor;
      void* hbrBackground;
      const char* lpszMenuName;
      const char* lpszClassName;
      void* hIconSm;
    } WNDCLASSEXA;
    
    typedef struct MSG {
      void* hwnd;
      uint32_t message;
      uintptr_t wParam, lParam;
      uint32_t time;
      POINT pt;
    } MSG;
    
    typedef struct SECURITY_ATTRIBUTES {
      uint32_t nLength;
      void* lpSecurityDescriptor;
      bool32 bInheritHandle;
    } SECURITY_ATTRIBUTES;
    
    void* GetModuleHandleA(const char* name);
    uint16_t RegisterClassExA(const WNDCLASSEXA*);
    intptr_t DefWindowProcA(void* hwnd, uint32_t msg, uintptr_t wparam, uintptr_t lparam);
    void PostQuitMessage(int exitCode);
    void* LoadIconA(void* hInstance, const char* iconName);
    void* LoadCursorA(void* hInstance, const char* cursorName);
    uint32_t GetLastError();
    void* CreateWindowExA(uint32_t exstyle,
      const char* classname,
      const char* windowname,
      int32_t style,
      int32_t x, int32_t y, int32_t width, int32_t height,
      void* parent_hwnd, void* hmenu, void* hinstance, void* param);
    bool32 ShowWindow(void* hwnd, int32_t command);
    bool32 UpdateWindow(void* hwnd);
    bool32 PeekMessageA(MSG* out_msg, void* hwnd, uint32_t filter_min, uint32_t filter_max, uint32_t removalMode);
    bool32 TranslateMessage(const MSG* msg);
    intptr_t DispatchMessageA(const MSG* msg);
    bool32 InvalidateRect(void* hwnd, const RECT*, bool32 erase);
    void* CreateEventA(SECURITY_ATTRIBUTES*, bool32 manualReset, bool32 initialState, const char* name);
    uint32_t MsgWaitForMultipleObjects(uint32_t count, void** handles, bool32 waitAll, uint32_t ms, uint32_t wakeMask);

  ]]

  return ffi.C
end

package.preload['extern.mswindows.winmm'] = function()
  local ffi = require 'ffi'
    
  ffi.cdef [[
  
    enum {
      TIME_PERIODIC = 0x1,
      TIME_CALLBACK_FUNCTION = 0x00,
      TIME_CALLBACK_EVENT_SET = 0x10,
      TIME_CALLBACK_EVENT_PULSE = 0x20
    };
    uint32_t timeSetEvent(uint32_t delayMs, uint32_t resolutionMs, void* callback_or_event, uintptr_t user, uint32_t eventType);
    
  ]]
  
  return ffi.load 'winmm'
end

package.preload['extern.mswindows.idi'] = function()

  local ffi = require 'ffi'

  return {
    APPLICATION = ffi.cast('const char*', 32512);
  }
  
end

package.preload['extern.mswindows.idc'] = function()

  local ffi = require 'ffi'

  return {
    ARROW = ffi.cast('const char*', 32512);
  }
  
end

local bit = require 'bit'
local ffi = require 'ffi'
local mswin = require 'extern.mswindows'
local winmm = require 'extern.mswindows.winmm'
local idi = require 'extern.mswindows.idi'
local idc = require 'extern.mswindows.idc'

local hInstance = mswin.GetModuleHandleA(nil)

local CLASS_NAME = 'TestWindowClass'

local reg = mswin.RegisterClassExA(ffi.new('WNDCLASSEXA', {
  cbSize = ffi.sizeof 'WNDCLASSEXA';
  style = bit.bor(mswin.CS_HREDRAW, mswin.CS_VREDRAW);
  lpfnWndProc = function(hwnd, msg, wparam, lparam)
    if (msg == mswin.WM_DESTROY) then
      mswin.PostQuitMessage(0)
      return 0
    end
    return mswin.DefWindowProcA(hwnd, msg, wparam, lparam)
  end;
  cbClsExtra = 0;
  cbWndExtra = 0;
  hInstance = hInstance;
  hIcon = mswin.LoadIconA(nil, idi.APPLICATION);
  hCursor = mswin.LoadCursorA(nil, idc.ARROW);
  hbrBackground = nil;
  lpszMenuName = nil;
  lpszClassName = CLASS_NAME;
  hIconSm = nil;
}))

if (reg == 0) then
  error('error #' .. mswin.GetLastError())
end

local testHwnd = mswin.CreateWindowExA(
  0,
  CLASS_NAME,
  'Test Window',
  mswin.WS_OVERLAPPEDWINDOW,
  320, 200,
  320, 200,
  nil,
  nil,
  hInstance,
  nil)
  
if (testHwnd == nil) then
  error 'unable to create window'
end

mswin.ShowWindow(testHwnd, mswin.SW_SHOW)
mswin.UpdateWindow(testHwnd)

local timerEvent = mswin.CreateEventA(nil, false, false, nil)
if (timerEvent == nil) then
  error('unable to create event')
end
local timer = winmm.timeSetEvent(25, 5, timerEvent, 0, bit.bor(winmm.TIME_PERIODIC, winmm.TIME_CALLBACK_EVENT_SET))
if (timer == 0) then
  error('unable to create timer')
end

local handleCount = 1
local handles = ffi.new('void*[1]', {timerEvent})

local msg = ffi.new 'MSG'

local quitting = false
while not quitting do
  local waitResult = mswin.MsgWaitForMultipleObjects(handleCount, handles, false, mswin.INFINITE, mswin.QS_ALLEVENTS)
  if (waitResult == mswin.WAIT_OBJECT_0+handleCount) then
    if (mswin.PeekMessageA(msg, nil, 0, 0, mswin.PM_REMOVE) ~= 0) then
      mswin.TranslateMessage(msg)
      mswin.DispatchMessageA(msg)		-- this is what may cause crash
										-- because it may trigger a callback from JIT to JIT code
										-- if it is wrapped in a jit.off() function it should be ok
      if (msg.message == mswin.WM_QUIT) then
        quitting = true
      end
    end
  elseif (waitResult == mswin.WAIT_OBJECT_0) then
    mswin.InvalidateRect(testHwnd, nil, false)
  else
    print 'unexpected event'
  end
end