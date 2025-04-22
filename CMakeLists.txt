# Distributed under the OSI-approved BSD 3-Clause License.
# See accompanying file LICENSE.txt for details.

cmake_minimum_required(VERSION 3.25)
project(mdbook-guide-l10n NONE)

#[============================================================[
# Cache Variables.
#]============================================================]

set(LANGUAGE "all"
    CACHE STRING "Language Code for the Sphinx documentation system.")
    # Possible values are "all" and languages listed in languages.json.
    # See https://www.sphinx-doc.org/en/master/usage/configuration.html#confval-language for details.

set(LANGUAGE_SOURCE "en_US"
    CACHE STRING "The source language code of the documentation")

set(VERSION "latest"
    CACHE STRING "Current version for the mdBook documentation.")
    # Possible values are "latest", "stable", and "0.4".

set(VERSION_COMPENDIUM "latest"
    CACHE STRING "Version of compendium that the current version merges translations from.")

set(AUTO_DEPEND ON
    CACHE BOOL "Enable automatic dependency management for specific build targets.")
    # Possible values are "ON/OFF", "TRUE/FALSE", "true/false"...etc.

set(REMOVE_REDUNDANT ON
    CACHE BOOL "Removing redundant files after building documentation.")
    # Possible values are "ON/OFF", "TRUE/FALSE", "true/false"...etc.

set(MODE_OF_UPDATE "NEVER"
    CACHE STRING "Mode of updating .pot/.po files.")
    # Possible values are "NEVER", "COMPARE", and "ALWAYS".
    # 1) NEVER:   Update .pot/.po files only if the current reference is missing.
    # 2) COMPARE: Update .pot/.po files only if the current reference is different than the latest one.
    # 3) ALWAYS:  Update .pot/.po files even if the current reference is the same as    the latest one.

set(MODE_OF_INSTALL "COMPARE"
    CACHE STRING "Mode of installing the requirements.")
    # Possible values are "COMPARE" and "ALWAYS".
    # 1) COMPARE: Install the requirements only if the current reference is different than the previous one.
    # 2) ALWAYS:  Install the requirements even if the current reference is the same as    the previous one.

set(MDBOOK_RENDERER "html"
    CACHE STRING "The renderer for the mdBook documentation system.")

set(GETTEXT_WRAP_WIDTH 79
    CACHE STRING "The Gettext wrap width for .pot/.po files.")

set(GETTEXT_MDBOOK_DEPTH 5
    CACHE STRING "The Gettext mdBook depth, passed to xgettext.depth")

set(REMOTE_URL_OF_L10N "https://github.com/hwhsu1231/mdbook-guide-l10n.git"
    CACHE STRING "Remote URL of the l10n Git repository.")

set(REMOTE_URL_OF_DOCS "https://github.com/rust-lang/mdBook.git"
    CACHE STRING "Remote URL of the docs Git repository.")

set(BASEURL_HREF "file://${PROJECT_SOURCE_DIR}/out/$CACHE{MDBOOK_RENDERER}"
    CACHE STRING "The base URL of the deployed documentation.")

set(VERSION_OF_RUST "[default]"
    CACHE STRING "The version of Rust to install.")

set(VERSION_OF_DASEL "[default]"
    CACHE STRING "The version of Dasel to install.")

set(VERSION_OF_MDBOOK "[default]"
    CACHE STRING "The version of mdBook to install.")

set(VERSION_OF_MDBOOK_I18N_HELPER "[default]"
    CACHE STRING "The version of mdbook-i18n-helper to install.")

#[============================================================[
# Directory-Related Variables.
#]============================================================]

set(PROJ_SOURCE_DIR                 "${PROJECT_SOURCE_DIR}")
set(PROJ_BINARY_DIR                 "${PROJECT_BINARY_DIR}")
set(PROJ_CMAKE_CUSTOM_DIR           "${PROJ_SOURCE_DIR}/cmake/custom")
set(PROJ_CMAKE_FLYOUT_DIR           "${PROJ_SOURCE_DIR}/cmake/flyout")
set(PROJ_CMAKE_MODULES_DIR          "${PROJ_SOURCE_DIR}/cmake/modules")
set(PROJ_CMAKE_TARGETS_DIR          "${PROJ_SOURCE_DIR}/cmake/targets")
set(PROJ_CONDA_DIR                  "${PROJ_SOURCE_DIR}/.conda")
set(PROJ_OUT_DIR                    "${PROJ_SOURCE_DIR}/out")
set(PROJ_OUT_REPO_DIR               "${PROJ_OUT_DIR}/repo")
set(PROJ_OUT_REPO_BOOK_DIR          "${PROJ_OUT_REPO_DIR}/guide")
set(PROJ_OUT_REPO_BOOK_SRC_DIR      "${PROJ_OUT_REPO_BOOK_DIR}/src")
set(PROJ_OUT_REPO_BOOK_THEME_DIR    "${PROJ_OUT_REPO_BOOK_DIR}/theme")
set(PROJ_OUT_REPO_BOOK_LOCALE_DIR   "${PROJ_OUT_REPO_BOOK_DIR}/locale")
set(PROJ_OUT_RENDERER_DIR           "${PROJ_OUT_DIR}/${MDBOOK_RENDERER}")
set(PROJ_L10N_DIR                   "${PROJ_SOURCE_DIR}/l10n")
set(PROJ_L10N_VERSION_DIR           "${PROJ_L10N_DIR}/${VERSION}")
set(PROJ_L10N_VERSION_LOCALE_DIR    "${PROJ_L10N_VERSION_DIR}/locale")
set(PROJ_L10N_VERSION_SINGLE_DIR    "${PROJ_L10N_VERSION_DIR}/.single")
set(PROJ_L10N_VERSION_CROWDIN_DIR   "${PROJ_L10N_VERSION_DIR}/.crowdin")

#[============================================================[
# Configuration Files.
#]============================================================]

set(LANGUAGES_JSON_PATH             "${PROJ_SOURCE_DIR}/languages.json")
set(PREV_PACKAGES_TXT_PATH          "${PROJ_CONDA_DIR}/prev/packages.txt")
set(PREV_REFERENCE_TXT_PATH         "${PROJ_CONDA_DIR}/prev/reference.txt")
set(REFERENCES_JSON_PATH            "${PROJ_L10N_VERSION_DIR}/references.json")
set(CROWDIN_YML_PATH                "${PROJ_L10N_VERSION_DIR}/crowdin.yml")
set(STATISTIC_TXT_PATH              "${PROJ_L10N_VERSION_DIR}/statistic.txt")

#[============================================================[
# Include CMake modules.
#]============================================================]

set(CMAKE_MODULE_PATH   "${PROJ_CMAKE_MODULES_DIR}")
include(LogUtils)
include(JsonUtils)

#[============================================================[
# Read LANGUAGE_LIST from languages.json.
#]============================================================]

file(READ "${LANGUAGES_JSON_PATH}"  LANGUAGES_JSON_CNT)
get_members_of_json_object(
    IN_JSON_OBJECT      "${LANGUAGES_JSON_CNT}"
    OUT_MEMBER_NAMES    LANGUAGE_LIST)

#[============================================================[
# Validate the VERSION cache variable.
# - For "latest":
#   - Set VERSION_TYPE    to "branch"
#   - Set BRANCH_NAME     to "master"
# - For "stable":
#   - Set VERSION_TYPE    to "tag"
#   - Set TAG_PATTERN     to "^v([0-9]+)\\.([0-9]+)\\.([0-9]+)(-rc[1-9][0-9]*)?$"
#   - Set TAG_SUFFIX      to "-rc"
# - For "[MAJOR].[MINOR]":
#   - Set VERSION_TYPE    to "tag"
#   - Set TAG_PATTERN     to "^v([MAJOR])\\.([MINOR])\\.([0-9]+)(-rc[1-9][0-9]*)?$"
#   - Set TAG_SUFFIX      to "-rc"
#]============================================================]

if     (VERSION MATCHES "^latest$")
    set(VERSION_TYPE    "branch")
    set(BRANCH_NAME     "master")
elseif (VERSION MATCHES "^stable$")
    set(VERSION_TYPE    "tag")
    set(TAG_PATTERN     "^v([0-9]+)\\.([0-9]+)\\.([0-9]+)(-rc[1-9][0-9]*)?$")
    set(TAG_SUFFIX      "-rc")
elseif (VERSION MATCHES "^([0-9]+)\\.([0-9]+)$")
    set(MAJOR           "${CMAKE_MATCH_1}")
    set(MINOR           "${CMAKE_MATCH_2}")
    set(VERSION_TYPE    "tag")
    set(TAG_PATTERN     "^v(${MAJOR})\\.(${MINOR})\\.([0-9]+)(-rc[1-9][0-9]*)?$")
    set(TAG_SUFFIX      "-rc")
else()
    message(FATAL_ERROR "Invalid VERSION value. (${VERSION})")
endif()

#[============================================================[
# Validate the LANGUAGE cache variable.
#]============================================================]

set(LANGUAGE_IS_VALID FALSE)
if (LANGUAGE STREQUAL "all")
    set(LANGUAGE_IS_VALID TRUE)
else()
    foreach(_LANGUAGE ${LANGUAGE_LIST})
        if (LANGUAGE STREQUAL _LANGUAGE)
            set(LANGUAGE_IS_VALID TRUE)
        endif()
    endforeach()
    unset(_LANGUAGE)
endif()
if (NOT LANGUAGE_IS_VALID)
    message(FATAL_ERROR "Invalid LANGUAGE value. (${LANGUAGE})")
endif()

#[============================================================[
# Validate the MODE_OF_UPDATE cache variable.
#]============================================================]

if (NOT MODE_OF_UPDATE STREQUAL "COMPARE" AND
    NOT MODE_OF_UPDATE STREQUAL "ALWAYS" AND
    NOT MODE_OF_UPDATE STREQUAL "NEVER")
    message(FATAL_ERROR "Invalid MODE_OF_UPDATE value. (${MODE_OF_UPDATE})")
endif()

#[============================================================[
# Validate the MODE_OF_INSTALL cache variable.
#]============================================================]

if (NOT MODE_OF_INSTALL STREQUAL "COMPARE" AND
    NOT MODE_OF_INSTALL STREQUAL "ALWAYS")
    message(FATAL_ERROR "Invalid MODE_OF_INSTALL value. (${MODE_OF_INSTALL})")
endif()

#[============================================================[
# Initialize VERSION_OF_XXX if CACHE{VERSION_OF_XXX} is "[default]".
# Set VERSION_OF_XXX to $CACHE{VERSION_OF_XX} if it's not "[default]".
#]============================================================]

if     (VERSION MATCHES "^latest$")
    set(VERSION_OF_RUST               "")
    set(VERSION_OF_DASEL              "")
    set(VERSION_OF_MDBOOK             "")
    set(VERSION_OF_MDBOOK_I18N_HELPER "")
elseif (VERSION MATCHES "^stable$")
    set(VERSION_OF_RUST               "")
    set(VERSION_OF_DASEL              "")
    set(VERSION_OF_MDBOOK             "")
    set(VERSION_OF_MDBOOK_I18N_HELPER "")
elseif (VERSION MATCHES "^([0-9]+)\\.([0-9]+)$")
    set(VERSION_OF_RUST               "")
    set(VERSION_OF_DASEL              "")
    set(VERSION_OF_MDBOOK             "^${VERSION}")
    set(VERSION_OF_MDBOOK_I18N_HELPER "")
else()
    message(FATAL_ERROR "Invalid VERSION value. (${VERSION})")
endif()
if (NOT "$CACHE{VERSION_OF_RUST}" STREQUAL "[default]")
    set(VERSION_OF_RUST "$CACHE{VERSION_OF_RUST}")
endif()
if (NOT "$CACHE{VERSION_OF_DASEL}" STREQUAL "[default]")
    set(VERSION_OF_DASEL "$CACHE{VERSION_OF_DASEL}")
endif()
if (NOT "$CACHE{VERSION_OF_MDBOOK}" STREQUAL "[default]")
    set(VERSION_OF_MDBOOK "$CACHE{VERSION_OF_MDBOOK}")
endif()
if (NOT "$CACHE{VERSION_OF_MDBOOK_I18N_HELPER}" STREQUAL "[default]")
    set(VERSION_OF_MDBOOK_I18N_HELPER "$CACHE{VERSION_OF_MDBOOK_I18N_HELPER}")
endif()

#[============================================================[
# Check prerequisites.
#]============================================================]

find_package(Git        MODULE QUIET)
find_package(Conda      MODULE QUIET)
find_package(Gettext    MODULE QUIET)
find_package(Crowdin    MODULE QUIET)

#[============================================================[
# Create Git Worktree for 'l10n' branch in ${PROJ_L10N_DIR}.
#]============================================================]

create_git_worktree_for_l10n_branch(
    IN_REMOTE_URL       "${REMOTE_URL_OF_L10N}"
    IN_LOCAL_PATH       "${PROJ_SOURCE_DIR}"
    IN_WORKTREE_PATH    "${PROJ_L10N_DIR}")

#[============================================================[
# Initialize ${REFERENCES_JSON_PATH}.
#]============================================================]

init_references_json_file(
    IN_FILEPATH         "${REFERENCES_JSON_PATH}"
    IN_VERSION          "${VERSION}"
    IN_TYPE             "${VERSION_TYPE}"
    IN_MODE             "language"
    IN_LANGUAGE         "${LANGUAGE_LIST}")

#[============================================================[
# Initialize ${CROWDIN_YML_PATH}.
#]============================================================]

file(COPY_FILE
    "${PROJ_CMAKE_CUSTOM_DIR}/crowdin.yml"
    "${CROWDIN_YML_PATH}")

#[============================================================[
# Print Information.
#]============================================================]

message(STATUS "---------- Cache Variables ----------")
message(STATUS "LANGUAGE                        = ${LANGUAGE}")
message(STATUS "LANGUAGE_SOURCE                 = ${LANGUAGE_SOURCE}")
message(STATUS "VERSION                         = ${VERSION}")
message(STATUS "VERSION_COMPENDIUM              = ${VERSION_COMPENDIUM}")
message(STATUS "AUTO_DEPEND                     = ${AUTO_DEPEND}")
message(STATUS "REMOVE_REDUNDANT                = ${REMOVE_REDUNDANT}")
message(STATUS "MODE_OF_UPDATE                  = ${MODE_OF_UPDATE}")
message(STATUS "MODE_OF_INSTALL                 = ${MODE_OF_INSTALL}")
message(STATUS "MDBOOK_RENDERER                 = ${MDBOOK_RENDERER}")
message(STATUS "GETTEXT_WRAP_WIDTH              = ${GETTEXT_WRAP_WIDTH}")
message(STATUS "GETTEXT_MDBOOK_DEPTH            = ${GETTEXT_MDBOOK_DEPTH}")
message(STATUS "REMOTE_URL_OF_L10N              = ${REMOTE_URL_OF_L10N}")
message(STATUS "REMOTE_URL_OF_DOCS              = ${REMOTE_URL_OF_DOCS}")
message(STATUS "BASEURL_HREF                    = ${BASEURL_HREF}")
message(STATUS "VERSION_OF_RUST                 = ${VERSION_OF_RUST} (CACHE: $CACHE{VERSION_OF_RUST})")
message(STATUS "VERSION_OF_DASEL                = ${VERSION_OF_DASEL} (CACHE: $CACHE{VERSION_OF_DASEL})")
message(STATUS "VERSION_OF_MDBOOK               = ${VERSION_OF_MDBOOK} (CACHE: $CACHE{VERSION_OF_MDBOOK})")
message(STATUS "VERSION_OF_MDBOOK_I18N_HELPER   = ${VERSION_OF_MDBOOK_I18N_HELPER} (CACHE: $CACHE{VERSION_OF_MDBOOK_I18N_HELPER})")
message(STATUS "---------- Directory-Related Variables ----------")
message(STATUS "PROJ_SOURCE_DIR                 = ${PROJ_SOURCE_DIR}")
message(STATUS "PROJ_BINARY_DIR                 = ${PROJ_BINARY_DIR}")
message(STATUS "PROJ_CMAKE_CUSTOM_DIR           = ${PROJ_CMAKE_CUSTOM_DIR}")
message(STATUS "PROJ_CMAKE_FLYOUT_DIR           = ${PROJ_CMAKE_FLYOUT_DIR}")
message(STATUS "PROJ_CMAKE_MODULES_DIR          = ${PROJ_CMAKE_MODULES_DIR}")
message(STATUS "PROJ_CMAKE_TARGETS_DIR          = ${PROJ_CMAKE_TARGETS_DIR}")
message(STATUS "PROJ_CONDA_DIR                  = ${PROJ_CONDA_DIR}")
message(STATUS "PROJ_OUT_DIR                    = ${PROJ_OUT_DIR}")
message(STATUS "PROJ_OUT_REPO_DIR               = ${PROJ_OUT_REPO_DIR}")
message(STATUS "PROJ_OUT_REPO_BOOK_DIR          = ${PROJ_OUT_REPO_BOOK_DIR}")
message(STATUS "PROJ_OUT_REPO_BOOK_SRC_DIR      = ${PROJ_OUT_REPO_BOOK_SRC_DIR}")
message(STATUS "PROJ_OUT_REPO_BOOK_THEME_DIR    = ${PROJ_OUT_REPO_BOOK_THEME_DIR}")
message(STATUS "PROJ_OUT_REPO_BOOK_LOCALE_DIR   = ${PROJ_OUT_REPO_BOOK_LOCALE_DIR}")
message(STATUS "PROJ_OUT_RENDERER_DIR           = ${PROJ_OUT_RENDERER_DIR}")
message(STATUS "PROJ_L10N_DIR                   = ${PROJ_L10N_DIR}")
message(STATUS "PROJ_L10N_VERSION_DIR           = ${PROJ_L10N_VERSION_DIR}")
message(STATUS "PROJ_L10N_VERSION_LOCALE_DIR    = ${PROJ_L10N_VERSION_LOCALE_DIR}")
message(STATUS "PROJ_L10N_VERSION_SINGLE_DIR    = ${PROJ_L10N_VERSION_SINGLE_DIR}")
message(STATUS "PROJ_L10N_VERSION_CROWDIN_DIR   = ${PROJ_L10N_VERSION_CROWDIN_DIR}")
message(STATUS "---------- Configuration Files ----------")
message(STATUS "LANGUAGES_JSON_PATH             = ${LANGUAGES_JSON_PATH}")
message(STATUS "PREV_PACKAGES_TXT_PATH          = ${PREV_PACKAGES_TXT_PATH}")
message(STATUS "PREV_REFERENCE_TXT_PATH         = ${PREV_REFERENCE_TXT_PATH}")
message(STATUS "REFERENCES_JSON_PATH            = ${REFERENCES_JSON_PATH}")
message(STATUS "CROWDIN_YML_PATH                = ${CROWDIN_YML_PATH}")
message(STATUS "STATISTIC_TXT_PATH              = ${STATISTIC_TXT_PATH}")
message(STATUS "---------- Other Variables ----------")
message(STATUS "LANGUAGE_LIST                   = ${LANGUAGE_LIST}")
message(STATUS "VERSION_TYPE                    = ${VERSION_TYPE}")
message(STATUS "BRANCH_NAME                     = ${BRANCH_NAME}")
message(STATUS "TAG_PATTERN                     = ${TAG_PATTERN}")
message(STATUS "TAG_SUFFIX                      = ${TAG_SUFFIX}")
message(STATUS "---------- Prerequisites ----------")
message(STATUS "CMAKE_VERSION                   = ${CMAKE_VERSION}")
message(STATUS "CMAKE_COMMAND                   = ${CMAKE_COMMAND}")
message(STATUS "CMAKE_GENERATOR                 = ${CMAKE_GENERATOR}")
message(STATUS "Git_FOUND                       = ${Git_FOUND}")
message(STATUS "Git_VERSION                     = ${Git_VERSION}")
message(STATUS "Git_EXECUTABLE                  = ${Git_EXECUTABLE}")
message(STATUS "Conda_FOUND                     = ${Conda_FOUND}")
message(STATUS "Conda_VERSION                   = ${Conda_VERSION}")
message(STATUS "Conda_EXECUTABLE                = ${Conda_EXECUTABLE}")
message(STATUS "Gettext_FOUND                   = ${Gettext_FOUND}")
message(STATUS "Gettext_VERSION                 = ${Gettext_VERSION}")
message(STATUS "Gettext_XGETTEXT_EXECUTABLE     = ${Gettext_XGETTEXT_EXECUTABLE}")
message(STATUS "Crowdin_FOUND                   = ${Crowdin_FOUND}")
message(STATUS "Crowdin_VERSION                 = ${Crowdin_VERSION}")
message(STATUS "Crowdin_EXECUTABLE              = ${Crowdin_EXECUTABLE}")
message(STATUS "----------------------------------------")

#[============================================================[
# Escape ';' characters for list variables.
#]============================================================]

string(REPLACE ";" "\\\\;" LANGUAGE_LIST "${LANGUAGE_LIST}")

#[============================================================[
# Environment variables passed to script mode.
#]============================================================]

set(SCRIPT_MODE_ENV
    PYTHONNOUSERSITE=1)

#[============================================================[
# Cache variables passed to script mode.
#]============================================================]

set(SCRIPT_MODE_CACHE
    # [Cache Variables]
    -D LANGUAGE=${LANGUAGE}
    -D LANGUAGE_SOURCE=${LANGUAGE_SOURCE}
    -D VERSION=${VERSION}
    -D VERSION_COMPENDIUM=${VERSION_COMPENDIUM}
    -D AUTO_DEPEND=${AUTO_DEPEND}
    -D REMOVE_REDUNDANT=${REMOVE_REDUNDANT}
    -D MODE_OF_UPDATE=${MODE_OF_UPDATE}
    -D MODE_OF_INSTALL=${MODE_OF_INSTALL}
    -D REMOTE_URL_OF_L10N=${REMOTE_URL_OF_L10N}
    -D REMOTE_URL_OF_DOCS=${REMOTE_URL_OF_DOCS}
    -D BASEURL_HREF=${BASEURL_HREF}
    -D MDBOOK_RENDERER=${MDBOOK_RENDERER}
    -D GETTEXT_WRAP_WIDTH=${GETTEXT_WRAP_WIDTH}
    -D GETTEXT_MDBOOK_DEPTH=${GETTEXT_MDBOOK_DEPTH}
    -D VERSION_OF_RUST=${VERSION_OF_RUST}
    -D VERSION_OF_DASEL=${VERSION_OF_DASEL}
    -D VERSION_OF_MDBOOK=${VERSION_OF_MDBOOK}
    -D VERSION_OF_MDBOOK_I18N_HELPER=${VERSION_OF_MDBOOK_I18N_HELPER}
    # [Directory-Related Variables]
    -D PROJ_SOURCE_DIR=${PROJ_SOURCE_DIR}
    -D PROJ_BINARY_DIR=${PROJ_BINARY_DIR}
    -D PROJ_CMAKE_CUSTOM_DIR=${PROJ_CMAKE_CUSTOM_DIR}
    -D PROJ_CMAKE_FLYOUT_DIR=${PROJ_CMAKE_FLYOUT_DIR}
    -D PROJ_CMAKE_MODULES_DIR=${PROJ_CMAKE_MODULES_DIR}
    -D PROJ_CMAKE_TARGETS_DIR=${PROJ_CMAKE_TARGETS_DIR}
    -D PROJ_CONDA_DIR=${PROJ_CONDA_DIR}
    -D PROJ_OUT_DIR=${PROJ_OUT_DIR}
    -D PROJ_OUT_REPO_DIR=${PROJ_OUT_REPO_DIR}
    -D PROJ_OUT_REPO_BOOK_DIR=${PROJ_OUT_REPO_BOOK_DIR}
    -D PROJ_OUT_REPO_BOOK_SRC_DIR=${PROJ_OUT_REPO_BOOK_SRC_DIR}
    -D PROJ_OUT_REPO_BOOK_THEME_DIR=${PROJ_OUT_REPO_BOOK_THEME_DIR}
    -D PROJ_OUT_REPO_BOOK_LOCALE_DIR=${PROJ_OUT_REPO_BOOK_LOCALE_DIR}
    -D PROJ_OUT_RENDERER_DIR=${PROJ_OUT_RENDERER_DIR}
    -D PROJ_L10N_DIR=${PROJ_L10N_DIR}
    -D PROJ_L10N_VERSION_DIR=${PROJ_L10N_VERSION_DIR}
    -D PROJ_L10N_VERSION_LOCALE_DIR=${PROJ_L10N_VERSION_LOCALE_DIR}
    -D PROJ_L10N_VERSION_SINGLE_DIR=${PROJ_L10N_VERSION_SINGLE_DIR}
    -D PROJ_L10N_VERSION_CROWDIN_DIR=${PROJ_L10N_VERSION_CROWDIN_DIR}
    # [Configuration Files]
    -D LANGUAGES_JSON_PATH=${LANGUAGES_JSON_PATH}
    -D PREV_PACKAGES_TXT_PATH=${PREV_PACKAGES_TXT_PATH}
    -D PREV_REFERENCE_TXT_PATH=${PREV_REFERENCE_TXT_PATH}
    -D REFERENCES_JSON_PATH=${REFERENCES_JSON_PATH}
    -D CROWDIN_YML_PATH=${CROWDIN_YML_PATH}
    -D STATISTIC_TXT_PATH=${STATISTIC_TXT_PATH}
    # [Other Variables]
    -D LANGUAGE_LIST=${LANGUAGE_LIST}
    -D VERSION_TYPE=${VERSION_TYPE}
    -D BRANCH_NAME=${BRANCH_NAME}
    -D TAG_PATTERN=${TAG_PATTERN}
    -D TAG_SUFFIX=${TAG_SUFFIX})

#[============================================================[
# Fundamental Targets.
#]============================================================]

add_custom_target(prepare_repositories
    COMMAND ${CMAKE_COMMAND} -E env ${SCRIPT_MODE_ENV}
            ${CMAKE_COMMAND} ${SCRIPT_MODE_CACHE}
            -P ${PROJ_CMAKE_TARGETS_DIR}/prepare_repositories.cmake
    VERBATIM)

add_custom_target(install_requirements
    COMMAND ${CMAKE_COMMAND} -E env ${SCRIPT_MODE_ENV}
            ${CMAKE_COMMAND} ${SCRIPT_MODE_CACHE}
            -P ${PROJ_CMAKE_TARGETS_DIR}/install_requirements.cmake
    VERBATIM)

add_custom_target(mdbook_update_pot
    COMMAND ${CMAKE_COMMAND} -E env ${SCRIPT_MODE_ENV}
            ${CMAKE_COMMAND} ${SCRIPT_MODE_CACHE}
            -P ${PROJ_CMAKE_TARGETS_DIR}/mdbook_update_pot.cmake
    VERBATIM)

add_custom_target(gettext_update_po
    COMMAND ${CMAKE_COMMAND} -E env ${SCRIPT_MODE_ENV}
            ${CMAKE_COMMAND} ${SCRIPT_MODE_CACHE}
            -P ${PROJ_CMAKE_TARGETS_DIR}/gettext_update_po.cmake
    VERBATIM)

add_custom_target(mdbook_build_docs ALL
    COMMAND ${CMAKE_COMMAND} -E env ${SCRIPT_MODE_ENV}
            ${CMAKE_COMMAND} ${SCRIPT_MODE_CACHE}
            -P ${PROJ_CMAKE_TARGETS_DIR}/mdbook_build_docs.cmake
    VERBATIM)

#[============================================================[
# Optional Targets.
#]============================================================]

add_custom_target(gettext_statistic_po
    COMMAND ${CMAKE_COMMAND} -E env ${SCRIPT_MODE_ENV}
            ${CMAKE_COMMAND} ${SCRIPT_MODE_CACHE}
            -P ${PROJ_CMAKE_TARGETS_DIR}/gettext_statistic_po.cmake
    VERBATIM)

add_custom_target(gettext_compend_po
    COMMAND ${CMAKE_COMMAND} -E env ${SCRIPT_MODE_ENV}
            ${CMAKE_COMMAND} ${SCRIPT_MODE_CACHE}
            -P ${PROJ_CMAKE_TARGETS_DIR}/gettext_compend_po.cmake
    VERBATIM)

add_custom_target(crowdin_upload_pot
    COMMAND ${CMAKE_COMMAND} -E env ${SCRIPT_MODE_ENV}
            ${CMAKE_COMMAND} ${SCRIPT_MODE_CACHE}
            -P ${PROJ_CMAKE_TARGETS_DIR}/crowdin_upload_pot.cmake
    VERBATIM)

add_custom_target(crowdin_download_po
    COMMAND ${CMAKE_COMMAND} -E env ${SCRIPT_MODE_ENV}
            ${CMAKE_COMMAND} ${SCRIPT_MODE_CACHE}
            -P ${PROJ_CMAKE_TARGETS_DIR}/crowdin_download_po.cmake
    VERBATIM)

#[============================================================[
# Add Dependencies for Fundamental Targets.
#]============================================================]

if (AUTO_DEPEND)
    add_dependencies(install_requirements   prepare_repositories)
    add_dependencies(mdbook_update_pot      install_requirements)
    add_dependencies(gettext_update_po      mdbook_update_pot)
    add_dependencies(mdbook_build_docs      gettext_update_po)
endif()
