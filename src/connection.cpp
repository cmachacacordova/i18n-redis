#include "i18n/redis/connection.h"

i18n::redis::Connection::Connection(const std::string &host, int port) {
  try {
    sw::redis::ConnectionOptions connectionOpts;
    connectionOpts.host = host;
    connectionOpts.port = port;

    sw::redis::ConnectionPoolOptions poolOpts;
    poolOpts.size = 4;
    poolOpts.wait_timeout = std::chrono::milliseconds(1000);
    poolOpts.connection_lifetime = std::chrono::milliseconds(60000);
    poolOpts.connection_idle_time = std::chrono::milliseconds(30000);

    redis_ = std::make_unique<sw::redis::Redis>(connectionOpts, poolOpts);
  } catch (const sw::redis::Error &e) { throw std::runtime_error(std::string("Failed to connect to Redis: ") + e.what()); }
}

i18n::redis::Connection::~Connection() noexcept = default;