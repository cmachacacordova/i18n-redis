#pragma once

/// @brief fmt format string used to build Redis keys for translations.
///
/// Arguments: locale (e.g. "en"), translation id (e.g. "greeting").
/// Resulting key example: "i18n:en:greeting".
#define I18N_FORMAT_KEY "i18n:{}:{}"