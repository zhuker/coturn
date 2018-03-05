cmake_minimum_required(VERSION 3.10)
project(coturn)

find_package(Threads REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(PkgConfig REQUIRED)
include(GNUInstallDirs REQUIRED)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(CoturnConfigurePkg)

set(CoturnAutodetectOptionalPkgs "TRUE" CACHE BOOL
    "Try to automatically detect which optional dependencies are installed")

RequiredPkg(Libevent        libevent)
RequiredPkg(LibeventThreads libevent_pthreads)
RequiredPkg(LibeventExtra   libevent_extra)
OptionalPkg(LibeventSSL     TURN_NO_TLS     libevent_openssl)
OptionalPkg(SQLite          TURN_NO_SQLITE  sqlite3)
OptionalPkg(MySQL           TURN_NO_MYSQL   mysql mariadb)
OptionalPkg(Postgres        TURN_NO_PQ      libpq)
OptionalPkg(MongoC          TURN_NO_MONGO   libmongoc-1.0 mongoc-1.0)
OptionalPkg(HiRedis         TURN_NO_HIREDIS hiredis)

message(STATUS "Compiling coturn with: ${CoturnOptionalPkgsDefinitions}")

# --- libturnclient.a ---
# This library has already been revealed to the world and must be maintained
# in a backward-compatible manner. It should not be thought as a mere
# implementation detail.
# NOTE: Please keep sources lists sorded here and below.

add_library(turnclient STATIC
    src/client/ns_turn_ioaddr.c
    src/client/ns_turn_ioaddr.h
    src/client/ns_turn_msg.c
    src/client/ns_turn_msg.h
    src/client/ns_turn_msg_addr.c
    src/client/ns_turn_msg_addr.h
    src/client/ns_turn_msg_defs.h
    src/client/ns_turn_msg_defs_experimental.h
    src/client++/TurnMsgLib.h
    src/ns_turn_defs.h
)

target_include_directories(turnclient
    PUBLIC src src/client
    PRIVATE src/apps/common
)

target_link_libraries(turnclient
    OpenSSL::SSL
    OpenSSL::Crypto
)

install(TARGETS turnclient
    ARCHIVE DESTINATION  "${CMAKE_INSTALL_FULL_LIBDIR}"
    INCLUDES DESTINATION "${CMAKE_INSTALL_FULL_INCLUDEDIR}"
)

install(FILES
    src/ns_turn_defs.h
    DESTINATION "${CMAKE_INSTALL_FULL_INCLUDEDIR}/turn"
)

install(FILES
    src/client/ns_turn_ioaddr.h
    src/client/ns_turn_msg.h
    src/client/ns_turn_msg_addr.h
    src/client/ns_turn_msg_defs.h
    src/client/ns_turn_msg_defs_experimental.h
    src/client++/TurnMsgLib.h
    DESTINATION "${CMAKE_INSTALL_FULL_INCLUDEDIR}/turn/client"
)

# --- turnserver and turnutils ---
# Since we have many similarly configured executable targets here, it's handier
# to use 'include_directories' once than write a bunch of almost identical
# 'target_include_directories' commands for each target. The same reasoning
# lies behind using 'add_definitions' and 'link_library' here.

add_definitions(
    ${CoturnOptionalPkgsDefinitions}
)

include_directories(
    src
    src/client
    src/server
    src/apps/common
)

link_libraries(
    turnclient
    Threads::Threads
    PkgConfig::Libevent
)

add_executable(turnserver
    src/apps/common/apputils.c
    src/apps/common/apputils.h
    src/apps/common/hiredis_libevent2.c
    src/apps/common/hiredis_libevent2.h
    src/apps/common/ns_turn_openssl.h
    src/apps/common/ns_turn_utils.c
    src/apps/common/ns_turn_utils.h
    src/apps/common/stun_buffer.c
    src/apps/common/stun_buffer.h
    src/apps/relay/dbdrivers/dbd_mongo.c
    src/apps/relay/dbdrivers/dbd_mongo.h
    src/apps/relay/dbdrivers/dbd_mysql.c
    src/apps/relay/dbdrivers/dbd_mysql.h
    src/apps/relay/dbdrivers/dbd_pgsql.c
    src/apps/relay/dbdrivers/dbd_pgsql.h
    src/apps/relay/dbdrivers/dbd_redis.c
    src/apps/relay/dbdrivers/dbd_redis.h
    src/apps/relay/dbdrivers/dbd_sqlite.c
    src/apps/relay/dbdrivers/dbd_sqlite.h
    src/apps/relay/dbdrivers/dbdriver.c
    src/apps/relay/dbdrivers/dbdriver.h
    src/apps/relay/dtls_listener.c
    src/apps/relay/dtls_listener.h
    src/apps/relay/http_server.c
    src/apps/relay/http_server.h
    src/apps/relay/libtelnet.c
    src/apps/relay/libtelnet.h
    src/apps/relay/mainrelay.c
    src/apps/relay/mainrelay.h
    src/apps/relay/netengine.c
    src/apps/relay/ns_ioalib_engine_impl.c
    src/apps/relay/ns_ioalib_impl.h
    src/apps/relay/ns_sm.h
    src/apps/relay/tls_listener.c
    src/apps/relay/tls_listener.h
    src/apps/relay/turn_admin_server.c
    src/apps/relay/turn_admin_server.h
    src/apps/relay/turn_ports.c
    src/apps/relay/turn_ports.h
    src/apps/relay/userdb.c
    src/apps/relay/userdb.h
    src/server/ns_turn_allocation.c
    src/server/ns_turn_allocation.h
    src/server/ns_turn_ioalib.h
    src/server/ns_turn_khash.h
    src/server/ns_turn_maps.c
    src/server/ns_turn_maps.h
    src/server/ns_turn_maps_rtcp.c
    src/server/ns_turn_maps_rtcp.h
    src/server/ns_turn_server.c
    src/server/ns_turn_server.h
    src/server/ns_turn_session.h
)

target_link_libraries(turnserver
    PkgConfig::LibeventThreads
    $<IF:$<BOOL:${CoturnWithLibeventSSL}>,PkgConfig::LibeventSSL,>
    $<IF:$<BOOL:${CoturnWithHiRedis}>,PkgConfig::HiRedis,>
    $<IF:$<BOOL:${CoturnWithMongoC}>,PkgConfig::MongoC,>
    $<IF:$<BOOL:${CoturnWithSQLite}>,PkgConfig::SQLite,>
    $<IF:$<BOOL:${CoturnWithMySQL}>,PkgConfig::MySQL,>
    $<IF:$<BOOL:${CoturnWithPostgres}>,PkgConfig::Postgres,>
)

add_executable(turnutils_uclient
    src/apps/common/apputils.c
    src/apps/common/ns_turn_utils.c
    src/apps/common/stun_buffer.c
    src/apps/uclient/mainuclient.c
    src/apps/uclient/session.h
    src/apps/uclient/startuclient.c
    src/apps/uclient/startuclient.h
    src/apps/uclient/uclient.c
    src/apps/uclient/uclient.h
)

add_executable(turnutils_oauth
    src/apps/common/apputils.c
    src/apps/common/ns_turn_utils.c
    src/apps/oauth/oauth.c
)

add_executable(turnutils_stunclient
    src/apps/common/apputils.c
    src/apps/common/ns_turn_utils.c
    src/apps/common/stun_buffer.c
    src/apps/stunclient/stunclient.c
)

add_executable(turnutils_rfc5769check
    src/apps/common/apputils.c
    src/apps/common/ns_turn_utils.c
    src/apps/rfc5769/rfc5769check.c
)

add_executable(turnutils_peer
    src/apps/common/apputils.c
    src/apps/common/ns_turn_utils.c
    src/apps/peer/mainudpserver.c
    src/apps/peer/udpserver.c
    src/apps/peer/udpserver.h
)

add_executable(turnutils_natdiscovery
    src/apps/common/apputils.c
    src/apps/common/ns_turn_utils.c
    src/apps/common/stun_buffer.c
    src/apps/natdiscovery/natdiscovery.c
)

add_custom_target(turnadmin ALL
    COMMAND "${CMAKE_COMMAND}" -E create_symlink turnserver turnadmin
    DEPENDS turnserver
)

install(TARGETS
    turnserver
    turnutils_natdiscovery
    turnutils_oauth
    turnutils_peer
    turnutils_rfc5769check
    turnutils_stunclient
    turnutils_uclient
    RUNTIME DESTINATION "${CMAKE_INSTALL_FULL_BINDIR}/"
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/turnadmin
    DESTINATION "${CMAKE_INSTALL_FULL_BINDIR}"
)

install(
    DIRECTORY man/man1/
    DESTINATION "${CMAKE_INSTALL_FULL_MANDIR}/man1"
    PATTERN *.1
)

install(FILES
    README.turnadmin
    README.turnserver
    README.turnutils
    INSTALL
    postinstall.txt
    DESTINATION "${CMAKE_INSTALL_FULL_DOCDIR}"
)

set(notUnwantedFileRegex "^\\w.*\\..*\\w$")
install(DIRECTORY
    turndb/
    DESTINATION "${CMAKE_INSTALL_FULL_DATADIR}/coturn"
    REGEX "${notUnwantedFileRegex}"
)

install(DIRECTORY
    examples/
    DESTINATION "${CMAKE_INSTALL_FULL_DOCDIR}/examples"
    REGEX "${notUnwantedFileRegex}"
)
