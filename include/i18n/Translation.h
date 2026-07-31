#pragma once

#include <memory>
#include <string>
#include <vector>

#include "i18n_redis_export.h"

#include "i18n/TranslationProvider.h"

#include "fmt/format.h"

namespace i18n {

/// @brief High-level facade for looking up and formatting translated strings.
///
/// Owns a @c TranslationProvider that handles the actual storage and retrieval.
/// Callers use @c store() once to load locale files and then @c translate()
/// for every lookup.
class I18N_REDIS_EXPORT Translation {
public:
  /// @brief Constructs a Translation with the given backend and default locale.
  /// @param provider Owning pointer to the translation backend.
  /// @param locale   BCP-47 tag used when @c translate() receives an empty locale.
  Translation(std::unique_ptr<TranslationProvider> provider, std::string locale = "en");

  /// @brief Loads locale files from disk through the underlying provider.
  /// @param cwd     Path to the directory that contains the "locales/" folder.
  /// @param locales Locale tags to load (e.g. {"en", "es"}).
  /// @return @c false if the provider is null, @c true if load was attempted.
  /// @note This method delegates to the provider's @c load() method and does not catch exceptions.
  ///       The provider's @c load() method may throw @c std::runtime_error on parsing errors or invalid translation data.
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
    return fmt::format(fmt::runtime(raw), std::forward<Args>(args)...);
  }

  /// @brief Retrieves and formats a translation with variadic fmt arguments using the default locale.
  ///
  /// The raw translation string may contain fmt placeholders (e.g. @c {}).
  /// Uses the default locale configured in the constructor.
  ///
  /// @tparam Args Pack of formatting argument types.
  /// @param key    Translation identifier.
  /// @param args   Arguments forwarded to @c fmt::vformat.
  /// @return Formatted translated string.
  template <typename... Args>
  std::string translate(const std::string &key, Args &&...args) const {
    return this->translate(key, this->m_default_locale, std::forward<Args>(args)...);
  }

  /// @brief Retrieves a translation without fmt formatting.
  /// @param key    Translation identifier.
  /// @param locale Target locale; falls back to the default when empty.
  /// @return Raw translated string (or @p key if not found).
  /// @note This method delegates to the provider's @c get() method and returns the result unchanged.
  std::string translate(const std::string &key, const std::string &locale) const;

  /// @brief Retrieves a translation without fmt formatting using the default locale.
  /// @param key Translation identifier.
  /// @return Raw translated string (or @p key if not found).
  std::string translate(const std::string &key) const;

  /// @brief Destructor that releases the translation provider.
  /// @note This destructor is noexcept and will not throw exceptions.
  ~Translation() noexcept;

private:
  std::unique_ptr<TranslationProvider> m_provider; ///< Backing store (e.g. Redis).
  std::string m_default_locale;                    ///< Fallback locale when none is specified.
};

} // namespace i18n
