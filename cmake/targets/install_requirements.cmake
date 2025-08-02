# Distributed under the OSI-approved BSD 3-Clause License.
# See accompanying file LICENSE-BSD for details.

cmake_minimum_required(VERSION 3.25)
get_filename_component(SCRIPT_NAME "${CMAKE_CURRENT_LIST_FILE}" NAME_WE)
set(CMAKE_MESSAGE_INDENT "[${VERSION}][${LANGUAGE}] ")
set(CMAKE_MESSAGE_INDENT_BACKUP "${CMAKE_MESSAGE_INDENT}")
message(STATUS "-------------------- ${SCRIPT_NAME} --------------------")


set(CMAKE_MODULE_PATH   "${PROJ_CMAKE_MODULES_DIR}")
find_package(Git        MODULE REQUIRED)
find_package(Conda      MODULE REQUIRED)
include(LogUtils)
include(GitUtils)
include(JsonUtils)


message(STATUS "Determining which reference to switch to...")
file(READ "${REFERENCES_JSON_PATH}" REFERENCES_JSON_CNT)
get_reference_of_latest_from_repo_and_current_from_json(
    IN_LOCAL_PATH                   "${PROJ_OUT_REPO_DIR}"
    IN_JSON_CNT                     "${REFERENCES_JSON_CNT}"
    IN_VERSION_TYPE                 "${VERSION_TYPE}"
    IN_BRANCH_NAME                  "${BRANCH_NAME}"
    IN_TAG_PATTERN                  "${TAG_PATTERN}"
    IN_TAG_SUFFIX                   "${TAG_SUFFIX}"
    IN_DOT_NOTATION                 ".pot"
    OUT_LATEST_OBJECT               LATEST_POT_OBJECT
    OUT_LATEST_REFERENCE            LATEST_POT_REFERENCE
    OUT_CURRENT_OBJECT              CURRENT_POT_OBJECT
    OUT_CURRENT_REFERENCE           CURRENT_POT_REFERENCE)
if (MODE_OF_UPDATE STREQUAL "COMPARE")
    if (NOT CURRENT_POT_REFERENCE STREQUAL LATEST_POT_REFERENCE)
        set(SWITCH_POT_REFERENCE    "${LATEST_POT_REFERENCE}")
    else()
        set(SWITCH_POT_REFERENCE    "${CURRENT_POT_REFERENCE}")
    endif()
elseif (MODE_OF_UPDATE STREQUAL "ALWAYS")
    set(SWITCH_POT_REFERENCE        "${LATEST_POT_REFERENCE}")
elseif (MODE_OF_UPDATE STREQUAL "NEVER")
    if (NOT CURRENT_POT_REFERENCE)
        set(SWITCH_POT_REFERENCE    "${LATEST_POT_REFERENCE}")
    else()
        set(SWITCH_POT_REFERENCE    "${CURRENT_POT_REFERENCE}")
    endif()
else()
    message(FATAL_ERROR "Invalid MODE_OF_UPDATE value. (${MODE_OF_UPDATE})")
endif()
remove_cmake_message_indent()
message("")
message("LATEST_POT_OBJECT      = ${LATEST_POT_OBJECT}")
message("CURRENT_POT_OBJECT     = ${CURRENT_POT_OBJECT}")
message("LATEST_POT_REFERENCE   = ${LATEST_POT_REFERENCE}")
message("CURRENT_POT_REFERENCE  = ${CURRENT_POT_REFERENCE}")
message("MODE_OF_UPDATE         = ${MODE_OF_UPDATE}")
message("SWITCH_POT_REFERENCE   = ${SWITCH_POT_REFERENCE}")
message("")
restore_cmake_message_indent()


message(STATUS "Switching to the reference '${SWITCH_POT_REFERENCE}' on the local branch 'current'...")
remove_cmake_message_indent()
message("")
switch_to_git_reference_on_branch(
    IN_LOCAL_PATH   "${PROJ_OUT_REPO_DIR}"
    IN_REFERENCE    "${SWITCH_POT_REFERENCE}"
    IN_BRANCH       "current")
message("")
restore_cmake_message_indent()


message(STATUS "Determining whether to install the requirements...")
set(CURRENT_REFERENCE "${SWITCH_POT_REFERENCE}")
if (EXISTS "${PREV_REFERENCE_TXT_PATH}")
    file(READ "${PREV_REFERENCE_TXT_PATH}" PREVIOUS_REFERENCE)
else()
    set(PREVIOUS_REFERENCE "")
endif()
if (MODE_OF_INSTALL STREQUAL "COMPARE")
    if (NOT CURRENT_REFERENCE STREQUAL PREVIOUS_REFERENCE)
        set(INSTALL_REQUIRED    ON)
    else()
        set(INSTALL_REQUIRED    OFF)
    endif()
elseif (MODE_OF_INSTALL STREQUAL "ALWAYS")
    set(INSTALL_REQUIRED        ON)
else()
    message(FATAL_ERROR "Invalid MODE_OF_INSTALL value. (${MODE_OF_INSTALL})")
endif()
remove_cmake_message_indent()
message("")
message("CURRENT_REFERENCE  = ${CURRENT_REFERENCE}")
message("PREVIOUS_REFERENCE = ${PREVIOUS_REFERENCE}")
message("MODE_OF_INSTALL    = ${MODE_OF_INSTALL}")
message("INSTALL_REQUIRED   = ${INSTALL_REQUIRED}")
message("")
restore_cmake_message_indent()


if (NOT INSTALL_REQUIRED)
    message(STATUS "No need to install the requirements.")
    return()
else()
    message(STATUS "Prepare to install the requirements.")
endif()


message(STATUS "Running 'conda create' command to (re)create the virtual environemnt...")
remove_cmake_message_indent()
message("")
execute_process(
    COMMAND ${Conda_EXECUTABLE} create
            --prefix ${PROJ_CONDA_DIR}
            --yes
    ECHO_OUTPUT_VARIABLE
    ECHO_ERROR_VARIABLE
    RESULT_VARIABLE RES_VAR
    OUTPUT_VARIABLE OUT_VAR OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE  ERR_VAR ERROR_STRIP_TRAILING_WHITESPACE)
if (RES_VAR EQUAL 0)
    if (ERR_VAR)
        string(APPEND WARNING_REASON
        "The command succeeded with warnings.\n\n"
        "    result:\n\n${RES_VAR}\n\n"
        "    stderr:\n\n${ERR_VAR}")
        message("${WARNING_REASON}")
    endif()
else()
    string(APPEND FAILURE_REASON
    "The command failed with fatal errors.\n"
    "    result:\n${RES_VAR}\n"
    "    stderr:\n${ERR_VAR}")
    message(FATAL_ERROR "${FAILURE_REASON}")
endif()
message("")
restore_cmake_message_indent()


message(STATUS "Running 'conda install' command to install dependencies...")
remove_cmake_message_indent()
message("")
execute_process(
    COMMAND ${Conda_EXECUTABLE} install
            conda-forge::rust=${VERSION_OF_RUST}
            conda-forge::dasel=${VERSION_OF_DASEL}
            --channel conda-forge
            --prefix ${PROJ_CONDA_DIR}
            --yes
    ECHO_OUTPUT_VARIABLE
    ECHO_ERROR_VARIABLE
    RESULT_VARIABLE RES_VAR
    OUTPUT_VARIABLE OUT_VAR OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE  ERR_VAR ERROR_STRIP_TRAILING_WHITESPACE)
if (RES_VAR EQUAL 0)
    if (ERR_VAR)
        string(APPEND WARNING_REASON
        "The command succeeded with warnings.\n\n"
        "    result:\n\n${RES_VAR}\n\n"
        "    stderr:\n\n${ERR_VAR}")
        message("${WARNING_REASON}")
    endif()
else()
    string(APPEND FAILURE_REASON
    "The command failed with fatal errors.\n"
    "    result:\n${RES_VAR}\n"
    "    stderr:\n${ERR_VAR}")
    message(FATAL_ERROR "${FAILURE_REASON}")
endif()
message("")
restore_cmake_message_indent()


if (CMAKE_HOST_LINUX)
    set(Cargo_ROOT_DIR  "${PROJ_CONDA_DIR}")
elseif (CMAKE_HOST_WIN32)
    set(Cargo_ROOT_DIR  "${PROJ_CONDA_DIR}/Library")
else()
    message(FATAL_ERROR "Invalid OS platform. (${CMAKE_HOST_SYSTEM_NAME})")
endif()
find_package(Cargo  MODULE REQUIRED)


message(STATUS "Running 'cargo install' command to install the 'mdbook' package from sources...")
if (CMAKE_HOST_LINUX)
    set(ENV_PATH                "${PROJ_CONDA_DIR}/bin:$ENV{PATH}")
    set(ENV_LD_LIBRARY_PATH     "${PROJ_CONDA_DIR}/lib:$ENV{ENV_LD_LIBRARY_PATH}")
    set(ENV_CARGO_INSTALL_ROOT  "${PROJ_CONDA_DIR}")
    set(ENV_VARS_OF_SYSTEM      PATH=${ENV_PATH}
                                LD_LIBRARY_PATH=${ENV_LD_LIBRARY_PATH}
                                CARGO_INSTALL_ROOT=${ENV_CARGO_INSTALL_ROOT})
elseif (CMAKE_HOST_WIN32)
    set(ENV_PATH                "${PROJ_CONDA_DIR}/bin"
                                "${PROJ_CONDA_DIR}/Scripts"
                                "${PROJ_CONDA_DIR}/Library/bin"
                                "${PROJ_CONDA_DIR}"
                                "$ENV{PATH}")
    set(ENV_CARGO_INSTALL_ROOT  "${PROJ_CONDA_DIR}/Library")
    string(REPLACE ";" "\\\\;" ENV_PATH "${ENV_PATH}")
    set(ENV_VARS_OF_SYSTEM      PATH=${ENV_PATH}
                                CARGO_INSTALL_ROOT=${ENV_CARGO_INSTALL_ROOT})
else()
    message(FATAL_ERROR "Invalid OS platform. (${CMAKE_HOST_SYSTEM_NAME})")
endif()
remove_cmake_message_indent()
message("")
execute_process(
    COMMAND ${CMAKE_COMMAND} -E env
            ${ENV_VARS_OF_SYSTEM}
            ${Cargo_EXECUTABLE} install
            --path ${PROJ_OUT_REPO_DIR}
            # --root ${CARGO_INSTALL_ROOT}
            --locked
    ECHO_OUTPUT_VARIABLE
    ECHO_ERROR_VARIABLE
    RESULT_VARIABLE RES_VAR
    OUTPUT_VARIABLE OUT_VAR OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE  ERR_VAR ERROR_STRIP_TRAILING_WHITESPACE)
if (RES_VAR EQUAL 0)
    if (ERR_VAR)
        string(APPEND WARNING_REASON
        "The command succeeded with warnings.\n\n"
        "    result:\n\n${RES_VAR}\n\n"
        "    stderr:\n\n${ERR_VAR}")
        message("${WARNING_REASON}")
    endif()
else()
    string(APPEND FAILURE_REASON
    "The command failed with fatal errors.\n"
    "    result:\n${RES_VAR}\n"
    "    stderr:\n${ERR_VAR}")
    message(FATAL_ERROR "${FAILURE_REASON}")
endif()
message("")
restore_cmake_message_indent()


# message(STATUS "Running 'cargo build' command to compile the project...")
# remove_cmake_message_indent()
# message("")
# execute_process(
#     COMMAND ${Cargo_EXECUTABLE} build
#             --manifest-path ${PROJ_OUT_REPO_DIR}/Cargo.toml
#             --target-dir ${PROJ_OUT_REPO_DIR}/target
#             # --artifact-dir ${PROJ_CONDA_DIR}
#             # -Z unstable-options
#             --release
#     WORKING_DIRECTORY ${PROJ_OUT_REPO_DIR}
#     ECHO_OUTPUT_VARIABLE
#     ECHO_ERROR_VARIABLE
#     RESULT_VARIABLE RES_VAR
#     OUTPUT_VARIABLE OUT_VAR OUTPUT_STRIP_TRAILING_WHITESPACE
#     ERROR_VARIABLE  ERR_VAR ERROR_STRIP_TRAILING_WHITESPACE)
# if (RES_VAR EQUAL 0)
#     if (ERR_VAR)
#         string(APPEND WARNING_REASON
#         "The command succeeded with warnings.\n\n"
#         "    result:\n\n${RES_VAR}\n\n"
#         "    stderr:\n\n${ERR_VAR}")
#         message("${WARNING_REASON}")
#     endif()
# else()
#     string(APPEND FAILURE_REASON
#     "The command failed with fatal errors.\n\n"
#     "    result:\n\n${RES_VAR}\n\n"
#     "    stderr:\n\n${ERR_VAR}")
#     message(FATAL_ERROR "${FAILURE_REASON}")
# endif()
# message("")
# restore_cmake_message_indent()


# message(STATUS "Copying 'mdbook' executable to the virtual environment...")
# if (CMAKE_HOST_WIN32)
#     set(MDBOOK_EXE  "mdbook.exe")
# else()
#     set(MDBOOK_EXE  "mdbook")
# endif()
# remove_cmake_message_indent()
# message("")
# execute_process(
#     COMMAND ${CMAKE_COMMAND} -E copy
#             ${PROJ_OUT_REPO_DIR}/target/release/${MDBOOK_EXE}
#             ${PROJ_CONDA_DIR}/bin/${MDBOOK_EXE}
#     ECHO_OUTPUT_VARIABLE
#     ECHO_ERROR_VARIABLE
#     RESULT_VARIABLE RES_VAR
#     OUTPUT_VARIABLE OUT_VAR OUTPUT_STRIP_TRAILING_WHITESPACE
#     ERROR_VARIABLE  ERR_VAR ERROR_STRIP_TRAILING_WHITESPACE)
# if (RES_VAR EQUAL 0)
#     if (ERR_VAR)
#         string(APPEND WARNING_REASON
#         "The command succeeded with warnings.\n\n"
#         "    result:\n\n${RES_VAR}\n\n"
#         "    stderr:\n\n${ERR_VAR}")
#         message("${WARNING_REASON}")
#     endif()
# else()
#     string(APPEND FAILURE_REASON
#     "The command failed with fatal errors.\n\n"
#     "    result:\n\n${RES_VAR}\n\n"
#     "    stderr:\n\n${ERR_VAR}")
#     message(FATAL_ERROR "${FAILURE_REASON}")
# endif()
# message("")
# restore_cmake_message_indent()


if (CMAKE_HOST_LINUX)
    set(mdBook_ROOT_DIR     "${PROJ_CONDA_DIR}")
elseif (CMAKE_HOST_WIN32)
    set(mdBook_ROOT_DIR     "${PROJ_CONDA_DIR}/Library")
else()
    message(FATAL_ERROR "Invalid OS platform. (${CMAKE_HOST_SYSTEM_NAME})")
endif()
find_package(mdBook    MODULE REQUIRED)


message(STATUS "Running 'cargo install' command to the specified packages...")
if (CMAKE_HOST_LINUX)
    set(ENV_PATH                "${PROJ_CONDA_DIR}/bin:$ENV{PATH}")
    set(ENV_LD_LIBRARY_PATH     "${PROJ_CONDA_DIR}/lib:$ENV{ENV_LD_LIBRARY_PATH}")
    set(ENV_CARGO_INSTALL_ROOT  "${PROJ_CONDA_DIR}")
    set(ENV_VARS_OF_SYSTEM      PATH=${ENV_PATH}
                                LD_LIBRARY_PATH=${ENV_LD_LIBRARY_PATH}
                                CARGO_INSTALL_ROOT=${ENV_CARGO_INSTALL_ROOT})
elseif (CMAKE_HOST_WIN32)
    set(ENV_PATH                "${PROJ_CONDA_DIR}/bin"
                                "${PROJ_CONDA_DIR}/Scripts"
                                "${PROJ_CONDA_DIR}/Library/bin"
                                "${PROJ_CONDA_DIR}"
                                "$ENV{PATH}")
    set(ENV_CARGO_INSTALL_ROOT  "${PROJ_CONDA_DIR}/Library")
    string(REPLACE ";" "\\\\;" ENV_PATH "${ENV_PATH}")
    set(ENV_VARS_OF_SYSTEM      PATH=${ENV_PATH}
                                CARGO_INSTALL_ROOT=${ENV_CARGO_INSTALL_ROOT})
else()
    message(FATAL_ERROR "Invalid OS platform. (${CMAKE_HOST_SYSTEM_NAME})")
endif()
if (NOT VERSION_OF_MDBOOK_I18N_HELPER STREQUAL "")
    set(VERSION_OF_MDBOOK_I18N_HELPER "@${VERSION_OF_MDBOOK_I18N_HELPER}")
endif()
remove_cmake_message_indent()
message("")
message("VERSION_OF_MDBOOK_I18N_HELPER  = ${VERSION_OF_MDBOOK_I18N_HELPER}")
message("")
execute_process(
    COMMAND ${CMAKE_COMMAND} -E env
            ${ENV_VARS_OF_SYSTEM}
            ${Cargo_EXECUTABLE} install
            mdbook-i18n-helpers${VERSION_OF_MDBOOK_I18N_HELPER}
            # --root ${CARGO_INSTALL_ROOT}
    ECHO_OUTPUT_VARIABLE
    ECHO_ERROR_VARIABLE
    RESULT_VARIABLE RES_VAR
    OUTPUT_VARIABLE OUT_VAR OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE  ERR_VAR ERROR_STRIP_TRAILING_WHITESPACE)
if (RES_VAR EQUAL 0)
    if (ERR_VAR)
        string(APPEND WARNING_REASON
        "The command succeeded with warnings.\n\n"
        "    result:\n\n${RES_VAR}\n\n"
        "    stderr:\n\n${ERR_VAR}")
        message("${WARNING_REASON}")
    endif()
else()
    string(APPEND FAILURE_REASON
    "The command failed with fatal errors.\n"
    "    result:\n${RES_VAR}\n"
    "    stderr:\n${ERR_VAR}")
    message(FATAL_ERROR "${FAILURE_REASON}")
endif()
message("")
restore_cmake_message_indent()


message(STATUS "The followings are the installed packages in Conda Environment...")
execute_process(
    COMMAND ${Conda_EXECUTABLE} list --export --prefix ${PROJ_CONDA_DIR}
    RESULT_VARIABLE RES_VAR
    OUTPUT_VARIABLE OUT_VAR OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE  ERR_VAR ERROR_STRIP_TRAILING_WHITESPACE)
remove_cmake_message_indent()
message("")
if (RES_VAR EQUAL 0)
    set(INSTALLED_PACKAGES  "${OUT_VAR}")
    message("${INSTALLED_PACKAGES}")
    if (ERR_VAR)
        string(APPEND WARNING_REASON
        "The command succeeded with warnings.\n\n"
        "    result:\n\n${RES_VAR}\n\n"
        "    stderr:\n\n${ERR_VAR}")
        message("${WARNING_REASON}")
    endif()
else()
    string(APPEND FAILURE_REASON
    "The command failed with fatal errors.\n"
    "    result:\n${RES_VAR}\n"
    "    stderr:\n${ERR_VAR}")
    message(FATAL_ERROR "${FAILURE_REASON}")
endif()
message("")
restore_cmake_message_indent()


file(WRITE "${PREV_REFERENCE_TXT_PATH}" "${CURRENT_REFERENCE}")
file(WRITE "${PREV_PACKAGES_TXT_PATH}"  "${INSTALLED_PACKAGES}")
