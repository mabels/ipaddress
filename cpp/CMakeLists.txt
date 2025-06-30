cmake_minimum_required (VERSION 3.11.0)
#include(CTest)
project (ipaddress)
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${ipaddress_SOURCE_DIR}/${CMAKE_BUILD_TYPE}/${CMAKE_SYSTEM_NAME})
SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${ipaddress_SOURCE_DIR}/${CMAKE_BUILD_TYPE}/${CMAKE_SYSTEM_NAME})
SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${ipaddress_SOURCE_DIR}/${CMAKE_BUILD_TYPE}/${CMAKE_SYSTEM_NAME})
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14 -Wall -Wextra")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF) 

if (${CMAKE_COMPILER_IS_GNUCXX})
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")
endif()

set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS} -g")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS} -O3 -g")

if(NOT GITBASE)
  set(GITBASE https://github.com)
endif()


cmake_policy(SET CMP0167 NEW)

#Only tested with versions 1.55 and 1.56
find_package(Boost 1.88 COMPONENTS system regex REQUIRED)
include_directories(${Boost_INCLUDE_DIR})

if(APPLE)
  set(CMAKE_MACOSX_RPATH 1)
#  set(OPENSSL_ROOT_DIR "/usr/local/opt/openssl")
endif()

#include(CMakeLists-easyloggingpp.txt)

include(CMakeLists-cascara.txt)


#set(SIMPLEWEB_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/3rdparty/Simple-WebSocket-Server")
#TODO: add requirement for version 1.0.1g (can it be done in one line?)
#find_package(OpenSSL REQUIRED)
#include_directories(${OPENSSL_INCLUDE_DIR})
#include_directories(${SIMPLEWEB_INCLUDE_DIR})

#find_package(Threads REQUIRED)

#include_directories(.)

file(GLOB SOURCES "src/*.cpp")
add_library(ipaddress SHARED ${SOURCES})
target_link_libraries(ipaddress ${Boost_LIBRARIES})

add_library(ipaddressStatic STATIC ${SOURCES})
target_link_libraries(ipaddressStatic ${Boost_LIBRARIES})
set_target_properties(ipaddressStatic PROPERTIES OUTPUT_NAME ipaddress)


install(TARGETS ipaddress ipaddressStatic
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib/static)
install(DIRECTORY src/ DESTINATION include/ipaddress FILES_MATCHING PATTERN "*.hpp")

enable_testing()
add_subdirectory(test)
