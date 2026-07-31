#pragma once

#include <string_view>

namespace i18n {

/// @brief fmt format string used to build Redis keys for translations.
///
/// Arguments: locale (e.g. "en"), translation id (e.g. "greeting").
/// Resulting key example: "i18n:en:greeting".
///
/// @note This format produces keys with the pattern "i18n:<locale>:<key>".
/// Translation IDs must not contain colons (":") as they are used as key delimiters.
inline constexpr std::string_view kFormatKey = "i18n:{}:{}";

} // namespace i18n