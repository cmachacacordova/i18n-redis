#pragma once

#include <string>

namespace i18n {

/// @brief Represents a single translation entry stored in Redis.
///
/// Each register holds the translation text for a specific key,
/// along with metadata such as category, timestamps, and version.
struct TranslationRegister {
  std::string m_id;                ///< Unique key that identifies this translation (no colons allowed).
  std::string m_value;             ///< The translated text.
  std::string m_category;          ///< Logical grouping/category for this translation.
  std::string m_creation_date;     ///< ISO-8601 date string when the entry was first created.
  std::string m_modification_date; ///< ISO-8601 date string of the last modification.
  int m_modification_version{0};   ///< Monotonically increasing version counter for this entry.
};

} // namespace i18n
