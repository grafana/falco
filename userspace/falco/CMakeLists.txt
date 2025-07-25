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

configure_file(config_falco.h.in config_falco.h)

add_library(
	falco_application STATIC
	app/app.cpp
	app/options.cpp
	app/restart_handler.cpp
	app/actions/helpers_generic.cpp
	app/actions/helpers_inspector.cpp
	app/actions/configure_interesting_sets.cpp
	app/actions/create_signal_handlers.cpp
	app/actions/pidfile.cpp
	app/actions/init_falco_engine.cpp
	app/actions/init_inspectors.cpp
	app/actions/init_outputs.cpp
	app/actions/list_fields.cpp
	app/actions/list_plugins.cpp
	app/actions/load_config.cpp
	app/actions/load_plugins.cpp
	app/actions/load_rules_files.cpp
	app/actions/process_events.cpp
	app/actions/print_generated_gvisor_config.cpp
	app/actions/print_help.cpp
	app/actions/print_ignored_events.cpp
	app/actions/print_kernel_version.cpp
	app/actions/print_plugin_info.cpp
	app/actions/print_support.cpp
	app/actions/print_syscall_events.cpp
	app/actions/print_version.cpp
	app/actions/print_page_size.cpp
	app/actions/configure_syscall_buffer_size.cpp
	app/actions/configure_syscall_buffer_num.cpp
	app/actions/select_event_sources.cpp
	app/actions/start_grpc_server.cpp
	app/actions/start_webserver.cpp
	app/actions/validate_rules_files.cpp
	app/actions/create_requested_paths.cpp
	app/actions/close_inspectors.cpp
	app/actions/print_config_schema.cpp
	app/actions/print_rule_schema.cpp
	configuration.cpp
	falco_outputs.cpp
	outputs_file.cpp
	outputs_stdout.cpp
	event_drops.cpp
	stats_writer.cpp
	versions_info.cpp
)

set(FALCO_INCLUDE_DIRECTORIES
	"${PROJECT_SOURCE_DIR}/userspace/engine" "${CMAKE_CURRENT_SOURCE_DIR}"
	"${CMAKE_CURRENT_BINARY_DIR}" "${PROJECT_BINARY_DIR}/driver/src" "${CXXOPTS_INCLUDE_DIR}"
)

set(FALCO_DEPENDENCIES cxxopts)
set(FALCO_LIBRARIES falco_engine)

if(USE_JEMALLOC)
	list(APPEND FALCO_DEPENDENCIES jemalloc)
	list(APPEND FALCO_LIBRARIES ${JEMALLOC_LIB})
endif()

target_sources(falco_application PRIVATE outputs_program.cpp outputs_syslog.cpp)

if(NOT MINIMAL_BUILD)
	target_sources(
		falco_application
		PRIVATE outputs_grpc.cpp
				outputs_http.cpp
				falco_metrics.cpp
				webserver.cpp
				grpc_context.cpp
				grpc_request_context.cpp
				grpc_server.cpp
				grpc_context.cpp
				${CMAKE_CURRENT_BINARY_DIR}/version.grpc.pb.cc
				${CMAKE_CURRENT_BINARY_DIR}/version.pb.cc
				${CMAKE_CURRENT_BINARY_DIR}/outputs.grpc.pb.cc
				${CMAKE_CURRENT_BINARY_DIR}/outputs.pb.cc
				${CMAKE_CURRENT_BINARY_DIR}/schema.pb.cc
	)

	list(
		APPEND
		FALCO_INCLUDE_DIRECTORIES
		FALCO_INCLUDE_DIRECTORIES
		"${OPENSSL_INCLUDE_DIR}"
		"${GRPC_INCLUDE}"
		"${GRPCPP_INCLUDE}"
		"${PROTOBUF_INCLUDE}"
		"${CARES_INCLUDE}"
	)

	if(USE_BUNDLED_GRPC)
		list(APPEND FALCO_DEPENDENCIES grpc)
	endif()

	if(USE_BUNDLED_CURL)
		list(APPEND FALCO_DEPENDENCIES curl)
	endif()

	list(
		APPEND
		FALCO_LIBRARIES
		httplib::httplib
		"${CURL_LIBRARIES}"
		"${GRPCPP_LIB}"
		"${GRPC_LIB}"
		"${GPR_LIB}"
		"${GRPC_LIBRARIES}"
		"${PROTOBUF_LIB}"
		"${CARES_LIB}"
	)
endif()

target_compile_definitions(falco_application PRIVATE CPPHTTPLIB_OPENSSL_SUPPORT)

add_dependencies(falco_application ${FALCO_DEPENDENCIES})

target_link_libraries(falco_application ${FALCO_LIBRARIES})

target_include_directories(falco_application PUBLIC ${FALCO_INCLUDE_DIRECTORIES})

add_executable(falco falco.cpp)
add_dependencies(falco falco_application ${FALCO_DEPENDENCIES})
target_link_libraries(falco falco_application ${FALCO_LIBRARIES})
target_include_directories(falco PUBLIC ${FALCO_INCLUDE_DIRECTORIES})

if(NOT MINIMAL_BUILD)
	add_custom_command(
		OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/version.grpc.pb.cc
			   ${CMAKE_CURRENT_BINARY_DIR}/version.grpc.pb.h
			   ${CMAKE_CURRENT_BINARY_DIR}/version.pb.cc
			   ${CMAKE_CURRENT_BINARY_DIR}/version.pb.h
			   ${CMAKE_CURRENT_BINARY_DIR}/outputs.grpc.pb.cc
			   ${CMAKE_CURRENT_BINARY_DIR}/outputs.grpc.pb.h
			   ${CMAKE_CURRENT_BINARY_DIR}/outputs.pb.cc
			   ${CMAKE_CURRENT_BINARY_DIR}/outputs.pb.h
			   ${CMAKE_CURRENT_BINARY_DIR}/schema.pb.cc
			   ${CMAKE_CURRENT_BINARY_DIR}/schema.pb.h
		COMMENT "Generate gRPC API"
		# Falco gRPC Version API
		DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/version.proto
		COMMAND ${PROTOC} -I ${CMAKE_CURRENT_SOURCE_DIR} --cpp_out=.
				${CMAKE_CURRENT_SOURCE_DIR}/version.proto
		COMMAND
			${PROTOC} -I ${CMAKE_CURRENT_SOURCE_DIR} --grpc_out=.
			--plugin=protoc-gen-grpc=${GRPC_CPP_PLUGIN} ${CMAKE_CURRENT_SOURCE_DIR}/version.proto
		# Falco gRPC Outputs API
		DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/outputs.proto
		COMMAND ${PROTOC} -I ${CMAKE_CURRENT_SOURCE_DIR} --cpp_out=.
				${CMAKE_CURRENT_SOURCE_DIR}/outputs.proto ${CMAKE_CURRENT_SOURCE_DIR}/schema.proto
		COMMAND
			${PROTOC} -I ${CMAKE_CURRENT_SOURCE_DIR} --grpc_out=.
			--plugin=protoc-gen-grpc=${GRPC_CPP_PLUGIN} ${CMAKE_CURRENT_SOURCE_DIR}/outputs.proto
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
	)
endif()

# strip the Falco binary when releasing using musl
if(MUSL_OPTIMIZED_BUILD AND CMAKE_BUILD_TYPE STREQUAL "release")
	add_custom_command(
		TARGET falco
		POST_BUILD
		COMMAND ${CMAKE_STRIP} --strip-unneeded falco
		COMMENT "Strip the Falco binary when releasing the musl build"
	)
endif()

if(CMAKE_BUILD_TYPE STREQUAL "relwithdebinfo")
	find_program(OBJCOPY_EXECUTABLE NAMES objcopy)
	if(OBJCOPY_EXECUTABLE)
		add_custom_command(
			TARGET falco
			POST_BUILD
			COMMAND ${OBJCOPY_EXECUTABLE} --only-keep-debug $<TARGET_FILE:falco>
					$<TARGET_FILE:falco>.debug
			COMMAND ${OBJCOPY_EXECUTABLE} --add-gnu-debuglink=$<TARGET_FILE:falco>.debug
					$<TARGET_FILE:falco>
			COMMENT "Generating separate debug file for falco"
		)
	else()
		message(WARNING "objcopy not found; separate debug files will not be generated.")
	endif()
endif()

install(TARGETS falco RUNTIME DESTINATION ${FALCO_BIN_DIR} COMPONENT "${FALCO_COMPONENT_NAME}")
