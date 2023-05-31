#ifndef FLUTTER_PLUGIN_MAGNIFYING_GLASS_PLUGIN_H_
#define FLUTTER_PLUGIN_MAGNIFYING_GLASS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace magnifying_glass {

class MagnifyingGlassPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MagnifyingGlassPlugin();

  virtual ~MagnifyingGlassPlugin();

  // Disallow copy and assign.
  MagnifyingGlassPlugin(const MagnifyingGlassPlugin&) = delete;
  MagnifyingGlassPlugin& operator=(const MagnifyingGlassPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace magnifying_glass

#endif  // FLUTTER_PLUGIN_MAGNIFYING_GLASS_PLUGIN_H_
