
cd ../glfw/src

cc -arch i386 -O3 -fPIC -D_GLFW_COCOA -D_GLFW_NSGL -D_GLFW_USE_OPENGL -D_GLFW_USE_MENUBAR  -D_GLFW_BUILD_DLL clipboard.c context.c gamma.c init.c input.c joystick.c monitor.c time.c window.c cocoa*.c cocoa*.m nsgl*.m -framework Cocoa -framework OpenGL -framework IOKit -framework CoreFoundation -framework CoreVideo -shared -o libglfw32.dylib

cc -arch x86_64 -O3 -fPIC -D_GLFW_COCOA -D_GLFW_NSGL -D_GLFW_USE_OPENGL -D_GLFW_USE_MENUBAR  -D_GLFW_BUILD_DLL clipboard.c context.c gamma.c init.c input.c joystick.c monitor.c time.c window.c cocoa*.c cocoa*.m nsgl*.m -framework Cocoa -framework OpenGL -framework IOKit -framework CoreFoundation -framework CoreVideo -shared -o libglfw64.dylib

lipo -create libglfw32.dylib libglfw64.dylib -output libglfw.dylib

rm libglfw32.dylib
rm libglfw64.dylib

cp libglfw.dylib ../../libluaav

cd ../../libluaav

luajit glfw_example.lua
