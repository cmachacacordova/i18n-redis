#include "i18n/redis/connection.h"

I18N_REDIS_EXPORT i18n::redis::Connection::Connection(const std::string &uri, int port) : redis_() {
  try {
    // Construct Redis connection options
    sw::redis::ConnectionOptions connection_opts;
    connection_opts.host = uri;
    connection_opts.port = port;
    sw::redis::ConnectionPoolOptions pool_opts;
    pool_opts.size = 4;                                                // Set the size of the connection pool
    pool_opts.wait_timeout = std::chrono::milliseconds(1000);          // Set wait timeout for connection pool
    pool_opts.connection_lifetime = std::chrono::milliseconds(60000);  // Set connection lifetime
    pool_opts.connection_idle_time = std::chrono::milliseconds(30000); // Set idle time for connections

    // Create Redis instance
    redis_ = std::make_unique<sw::redis::Redis>(connection_opts, pool_opts);

  } catch (const sw::redis::Error &e) { throw std::runtime_error("Failed to connect to Redis: " + std::string(e.what())); }
}

I18N_REDIS_EXPORT i18n::redis::Connection::~Connection() {}
