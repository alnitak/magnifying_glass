//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <magnifying_glass/magnifying_glass_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) magnifying_glass_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MagnifyingGlassPlugin");
  magnifying_glass_plugin_register_with_registrar(magnifying_glass_registrar);
}
