# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2023 The Falco Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#

set(CPACK_PACKAGE_NAME "${PACKAGE_NAME}")
set(CPACK_PACKAGE_VENDOR "Cloud Native Computing Foundation (CNCF) cncf.io.")
set(CPACK_PACKAGE_CONTACT "cncf-falco-dev@lists.cncf.io") # todo: change this once we've got
# @falco.org addresses
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Falco - Container Native Runtime Security")
set(CPACK_PACKAGE_DESCRIPTION_FILE "${PROJECT_SOURCE_DIR}/scripts/description.txt")
set(CPACK_PACKAGE_VERSION "${FALCO_VERSION}")
set(CPACK_PACKAGE_VERSION_MAJOR "${FALCO_VERSION_MAJOR}")
set(CPACK_PACKAGE_VERSION_MINOR "${FALCO_VERSION_MINOR}")
set(CPACK_PACKAGE_VERSION_PATCH "${FALCO_VERSION_PATCH}")
set(CPACK_PROJECT_CONFIG_FILE "${PROJECT_SOURCE_DIR}/cmake/cpack/CMakeCPackOptions.cmake")
set(CPACK_STRIP_FILES "OFF")
set(CPACK_PACKAGE_RELOCATABLE "OFF")
if(EMSCRIPTEN)
	set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-wasm")
else()
	set(CPACK_PACKAGE_FILE_NAME
		"${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_PROCESSOR}"
	)
endif()

# Built packages will include only the following components
set(CPACK_INSTALL_CMAKE_PROJECTS
	"${CMAKE_CURRENT_BINARY_DIR};${FALCO_COMPONENT_NAME};${FALCO_COMPONENT_NAME};/"
)

list(APPEND CPACK_INSTALL_CMAKE_PROJECTS
	 "${CMAKE_CURRENT_BINARY_DIR};${DRIVER_COMPONENT_NAME};${DRIVER_COMPONENT_NAME};/"
)

if(NOT CPACK_GENERATOR)
	set(CPACK_GENERATOR TGZ)
endif()

message(STATUS "Using package generators: ${CPACK_GENERATOR}")
message(STATUS "Package architecture: ${CMAKE_SYSTEM_PROCESSOR}")

include(CPack)
