#pragma once

#include "i18n_redis_export.h"

#include <memory>
#include <string>
#include <vector>

#include "i18n/translation_provider.h"

#include <fmt/core.h>

namespace i18n {

/// @brief High-level facade for looking up and formatting translated strings.
///
/// Owns a @c TranslationProvider that handles the actual storage and retrieval.
/// Callers use @c store() once to load locale files and then @c translate()
/// for every lookup.
class I18N_REDIS_EXPORT Translation {
private:
  std::unique_ptr<TranslationProvider> m_provider; ///< Backing store (e.g. Redis).
  std::string m_default_locale;                    ///< Fallback locale when none is specified.

public:
  /// @brief Constructs a Translation with the given backend and default locale.
  /// @param provider Owning pointer to the translation backend.
  /// @param locale   BCP-47 tag used when @c translate() receives an empty locale.
  Translation(std::unique_ptr<TranslationProvider> provider, std::string locale);

  /// @brief Loads locale files from disk through the underlying provider.
  /// @param cwd     Path to the directory that contains the "locales/" folder.
  /// @param locales Locale tags to load (e.g. {"en", "es"}).
  /// @return @c true if the provider loaded at least one locale successfully.
  bool store(const std::string &cwd, const std::vector<std::string> &locales);

  /// @brief Retrieves and formats a translation with variadic fmt arguments.
  ///
  /// The raw translation string may contain fmt placeholders (e.g. @c {}).
  /// If @p locale is empty the default locale is used.
  ///
  /// @tparam Args    Pack of formatting argument types.
  /// @param key      Translation identifier.
  /// @param locale   Target locale; falls back to the default when empty.
  /// @param args     Arguments forwarded to @c fmt::vformat.
  /// @return Formatted translated string.
  template <typename... Args>
  std::string translate(const std::string &key, const std::string &locale, Args &&...args) const {
    const std::string &used_locale = locale.empty() ? m_default_locale : locale;
    const std::string raw = m_provider->get(key, used_locale);
    return fmt::vformat(raw, fmt::make_format_args(args...));
  }

  /// @brief Retrieves a translation without fmt formatting.
  /// @param key    Translation identifier.
  /// @param locale Target locale; falls back to the default when empty.
  /// @return Raw translated string (or @p key if not found).
  std::string translate(const std::string &key, const std::string &locale = "") const;

  ~Translation() noexcept;
};

} // namespace i18n
