include(../common.pri)

TEMPLATE = lib
CONFIG += qt plugin link_pkgconfig
DEPENDPATH += ../src
INCLUDEPATH += ../src

QT = core dbus qml

LIBS += -L../src -l$${MPRISQTLIB}

#
# make sure qtmpris can find qtdbusextended build by clickable
#
isEmpty(ARCH_TRIPLET) {
  ARCH_TRIPLET=arm-linux-gnueabihf
  L_ARCH = $$system(dpkg-architecture -qDEB_HOST_MULTIARCH)
  contains( L_ARCH, x86_64-linux-gnu ) {
    message( "This looks like x86_64-linux-gnu ($$L_ARCH) to me." )
    ARCH_TRIPLET=x86_64-linux-gnu
  }
  message("ARCH_TRIPLET env var not found. Set to: $$ARCH_TRIPLET")
} else {
  message("ARCH_TRIPLET env var: $$ARCH_TRIPLET")
}
QTDBUSEXTENDED=$$PWD/../../../build/$$ARCH_TRIPLET/qtdbusextended/install
PKG_CONFIG = PKG_CONFIG_PATH=$$QTDBUSEXTENDED/usr/lib/$$ARCH_TRIPLET/pkgconfig pkg-config
INCLUDEPATH += $$QTDBUSEXTENDED/usr/include/$$ARCH_TRIPLET/qt5/DBusExtended
LIBS += -L$$QTDBUSEXTENDED/usr/lib/$$ARCH_TRIPLET
# 


PKGCONFIG = dbusextended-qt5

EXAMPLE = ../example/declarative/*

OTHER_FILES += $${EXAMPLE}

TARGET = $${MPRISQTLIB}-qml-plugin
PLUGIN_IMPORT_PATH = org/nemomobile/mpris

QMAKE_SUBSTITUTES = qmldir.in

SOURCES += \
    mprisplugin.cpp

HEADERS += \
    mprisplugin.h

#target.path = $$[QT_INSTALL_QML]/$$PLUGIN_IMPORT_PATH
target.path = $$[QT_INSTALL_LIBS]/$$PLUGIN_IMPORT_PATH

qml.files = qmldir plugins.qmltypes
qml.path = $$target.path
INSTALLS += target qml

qmltypes.commands = qmlplugindump -nonrelocatable org.nemomobile.mpris 1.0 > $$PWD/plugins.qmltypes
QMAKE_EXTRA_TARGETS += qmltypes
