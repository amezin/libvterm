get_filename_component(INCFILE_PATH ${INCFILE} PATH)
file(MAKE_DIRECTORY ${INCFILE_PATH})

execute_process(COMMAND ${PERL_EXECUTABLE}
                        -CSD ${CMAKE_CURRENT_LIST_DIR}/tbl2inc_c.pl
                        ${TBLFILE}
                OUTPUT_FILE ${INCFILE}
                RESULT_VARIABLE EXIT_CODE)

if(EXIT_CODE)
  message(FATAL_ERROR "tbl2inc_c.pl exited with code ${EXIT_CODE}")
endif()
