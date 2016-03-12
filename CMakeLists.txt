cmake_minimum_required(VERSION 2.8.7)
project(libvterm C)

find_package(Perl REQUIRED)

file(GLOB CFILES src/*.c)
file(GLOB HFILES include/*.h)
file(GLOB HFILES_INT src/*.h)
file(GLOB TBLFILES src/encoding/*.tbl)
file(GLOB BINFILES_SRC bin/*.c)

# Generate .inc files

unset(INCFILES)
foreach(TBLFILE ${TBLFILES})
  get_filename_component(TBLFILE_NAME_WE ${TBLFILE} NAME_WE)
  set(INCFILE ${CMAKE_CURRENT_BINARY_DIR}/encoding/${TBLFILE_NAME_WE}.inc)

  add_custom_command(OUTPUT ${INCFILE}
                     COMMAND ${CMAKE_COMMAND}
                             -DPERL_EXECUTABLE=${PERL_EXECUTABLE}
                             -DINCFILE=${INCFILE}
                             -DTBLFILE=${TBLFILE}
                             -P ${CMAKE_CURRENT_SOURCE_DIR}/tbl2inc_c.cmake
                     DEPENDS ${TBLFILE}
                             tbl2inc_c.cmake
                             tbl2inc_c.pl)

  list(APPEND INCFILES ${INCFILE})
endforeach()

# Extract version info from Makefile

file(STRINGS Makefile MAKEFILE)
foreach(VARNAME VERSION_MAJOR VERSION_MINOR VERSION_CURRENT VERSION_REVISION VERSION_AGE)
  foreach(MAKEFILE_LINE ${MAKEFILE})
    string(REGEX MATCH "^${VARNAME}=(.*)$" MATCH ${MAKEFILE_LINE})
    if(MATCH)
      set(${VARNAME} ${CMAKE_MATCH_1})
    endif()
  endforeach()
endforeach()

# Write .pc file

set(VERSION ${VERSION_MAJOR}.${VERSION_MINOR})
set(PREFIX ${CMAKE_INSTALL_PREFIX})
set(LIBDIR ${PREFIX}/lib)
configure_file(vterm.pc.in vterm.pc @ONLY)

# Set C standard version

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

if(CMAKE_VERSION VERSION_LESS 3.1)
  if(NOT MSVC) # Just in case
    add_definitions(-std=c99)
  endif()
endif()

# Compile the library

include_directories(include)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

if(CMAKE_BUILD_TYPE MATCHES "Debug")
  add_definitions(-DDEBUG)
endif()

add_library(libvterm ${CFILES} ${HFILES} ${HFILES_INT} ${INCFILES} ${TBLFILES})

math(EXPR SOVERSION "${VERSION_CURRENT}-${VERSION_AGE}")
set_target_properties(libvterm PROPERTIES
                      PREFIX ""
                      VERSION ${VERSION_CURRENT}.${VERSION_AGE}.${VERSION_REVISION}
                      SOVERSION ${SOVERSION})

# Compile tools from bin/

unset(BINFILES)
foreach(BINFILE_SRC ${BINFILES_SRC})
  get_filename_component(BINFILE ${BINFILE_SRC} NAME_WE)
  add_executable(${BINFILE} ${BINFILE_SRC})
  target_link_libraries(${BINFILE} libvterm)
  list(APPEND BINFILES ${BINFILE})
endforeach()

# Install

# _DISABLE_INSTALL flag will be useful when including the library using add_subdirectory()
if(NOT LIBVTERM_DISABLE_INSTALL)
  install(TARGETS libvterm DESTINATION lib)
  install(TARGETS ${BINFILES} DESTINATION bin)
  install(FILES ${HFILES} DESTINATION include)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/vterm.pc DESTINATION lib/pkgconfig)
endif()

# Uninstall
configure_file(cmake_uninstall.cmake.in cmake_uninstall.cmake IMMEDIATE @ONLY)
add_custom_target(uninstall "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake") 
