cmake_minimum_required(VERSION 3.21)

project(ClaudeUsageMonitor VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(APP_VERSION "${PROJECT_VERSION}" CACHE STRING "Version reported by the app and used for packages")

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick Widgets Concurrent)
find_package(PkgConfig REQUIRED)
pkg_check_modules(XCB REQUIRED IMPORTED_TARGET xcb)

qt_standard_project_setup(REQUIRES 6.5)
if(QT_KNOWN_POLICY_QTP0004)
    qt_policy(SET QTP0004 NEW)
endif()

qt_add_executable(claude-usage-monitor
    src/main.cpp
    src/UsageWatcher.h
    src/UsageWatcher.cpp
    src/TodayScanner.h
    src/TodayScanner.cpp
    src/ClaudeSetup.h
    src/ClaudeSetup.cpp
    src/TrayController.h
    src/TrayController.cpp
)

set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(claude-usage-monitor
    URI ClaudeUsage
    VERSION 1.0
    QML_FILES
        qml/main.qml
        qml/Theme.qml
        qml/PopupWindow.qml
        qml/Header.qml
        qml/RefreshButton.qml
        qml/GaugePanel.qml
        qml/CircularGauge.qml
        qml/UsageRow.qml
        qml/IconBadge.qml
        qml/IconButton.qml
        qml/WindowControls.qml
        qml/CompactPanel.qml
        qml/ProfileTabs.qml
    RESOURCES
        resources/claude-icon.svg
        resources/icons/alarm.svg
        resources/icons/calendar.svg
        resources/statusline.sh
)

target_compile_options(claude-usage-monitor PRIVATE -Wall -Wextra)
target_compile_definitions(claude-usage-monitor PRIVATE PROJECT_VERSION_STRING="${APP_VERSION}")

target_link_libraries(claude-usage-monitor PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Widgets
    Qt6::Concurrent
    PkgConfig::XCB
)

include(GNUInstallDirs)
install(TARGETS claude-usage-monitor RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES resources/claude-usage-monitor.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
install(FILES resources/claude-icon.svg
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
        RENAME claude-usage-monitor.svg)

# Debian package: `cpack -G DEB` from the build directory.
set(CPACK_PACKAGE_NAME claude-usage-monitor)
set(CPACK_PACKAGE_VERSION "${APP_VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "System tray monitor for Claude usage limits")
set(CPACK_PACKAGE_CONTACT "Claude Usage Monitor maintainers" CACHE STRING "Debian Maintainer field")
set(CPACK_PACKAGING_INSTALL_PREFIX /usr)
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
set(CPACK_DEBIAN_PACKAGE_SECTION utils)
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
# QML modules and plugins are loaded at runtime, so shlibdeps can't see them.
set(CPACK_DEBIAN_PACKAGE_DEPENDS
    "jq, qml6-module-qtcore, qml6-module-qtquick, qml6-module-qtquick-window, qml6-module-qtquick-layouts, qml6-module-qtquick-shapes, qml6-module-qtquick-effects, qt6-svg-plugins")
set(CPACK_DEBIAN_PACKAGE_RECOMMENDS "gnome-shell-extension-appindicator")
include(CPack)
