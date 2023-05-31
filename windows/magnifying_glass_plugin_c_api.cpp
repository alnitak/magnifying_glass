#include "include/magnifying_glass/magnifying_glass_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "magnifying_glass_plugin.h"

void MagnifyingGlassPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  magnifying_glass::MagnifyingGlassPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
