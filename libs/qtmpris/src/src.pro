include(../common.pri)

TEMPLATE = lib
CONFIG += qt link_pkgconfig

QT = core dbus qml

# set paths to qtdbusextended
#ARCH_TRIPLET=x86_64-linux-gnu
ARCH_TRIPLET=arm-linux-gnueabihf
QTDBUSEXTENDED=$$PWD/../../../build/$$ARCH_TRIPLET/qtdbusextended/install
PKG_CONFIG = PKG_CONFIG_PATH=$$QTDBUSEXTENDED/usr/lib/$$ARCH_TRIPLET/pkgconfig pkg-config
INCLUDEPATH += $$QTDBUSEXTENDED/usr/include/$$ARCH_TRIPLET/qt5/DBusExtended
LIBS += -L$$QTDBUSEXTENDED/usr/lib/$$ARCH_TRIPLET

PKGCONFIG = dbusextended-qt5
TARGET = $${MPRISQTLIB}

QMAKE_SUBSTITUTES = $${TARGET}.prf.in

DEFINES += MPRIS_QT_LIBRARY

# Generate pkg-config support by default
# Note that we HAVE TO also create prl config as QMake implementation
# mixes both of them together.
CONFIG += create_pc create_prl no_install_prl

SOURCES += \
    mpris.cpp \
    mprisrootadaptor.cpp \
    mprisplayeradaptor.cpp \
    mprisplayer.cpp \
    mpriscontroller.cpp \
    mprismanager.cpp \
    mprisplayerinterface.cpp \
    mprisrootinterface.cpp

HEADERS += \
    mprisqt.h \
    mpris.h \
    mprisplayer.h \
    mprisplayer_p.h \
    mpriscontroller.h \
    mpriscontroller_p.h \
    mprismanager.h

INSTALL_HEADERS = \
    MprisQt \
    Mpris \
    MprisPlayer \
    MprisController \
    MprisManager \
    mprisqt.h \
    mpris.h \
    mprisplayer.h \
    mpriscontroller.h \
    mprismanager.h

OTHER_FILES += org.mpris.MediaPlayer2.xml \
    org.mpris.MediaPlayer2.Player.xml

target.path = $$[QT_INSTALL_LIBS]
headers.files = $$INSTALL_HEADERS
headers.path = $$[QT_INSTALL_HEADERS]/MprisQt
prf.files = $${TARGET}.prf
prf.path = $$[QMAKE_MKSPECS]/features
INSTALLS += target headers prf

QMAKE_PKGCONFIG_REQUIRES = Qt5Core Qt5DBus dbusextended-qt5
QMAKE_PKGCONFIG_LIBDIR = $$target.path
QMAKE_PKGCONFIG_INCDIR = $$headers.path
QMAKE_PKGCONFIG_DESTDIR = pkgconfig
QMAKE_PKGCONFIG_NAME = MprisQt
