
########################################################
# Files

SET(PG_SRCS
  qgspostgresprovider.cpp
  qgspostgresconn.cpp
  qgspostgresconnpool.cpp
  qgspostgresdataitems.cpp
  qgspostgresfeatureiterator.cpp
  qgspostgrestransaction.cpp
  qgspgsourceselect.cpp
  qgspgnewconnection.cpp
  qgspgtablemodel.cpp
  qgscolumntypethread.cpp
  qgspostgresexpressioncompiler.cpp
)
SET(PG_MOC_HDRS
  qgspostgresprovider.h
  qgspostgresconn.h
  qgspostgresconnpool.h
  qgspostgresdataitems.h
  qgspgsourceselect.h
  qgspgnewconnection.h
  qgspgtablemodel.h
  qgscolumntypethread.h
)

SET(PG_HDRS
  qgspostgrestransaction.h
  qgspostgresexpressioncompiler.h
)

########################################################
# Build

QT4_WRAP_CPP(PG_MOC_SRCS ${PG_MOC_HDRS})

INCLUDE_DIRECTORIES(
  ../../core
  ../../core/auth
  ../../core/geometry
)
INCLUDE_DIRECTORIES(SYSTEM
  ${POSTGRES_INCLUDE_DIR}
  ${GEOS_INCLUDE_DIR}
  ${QSCINTILLA_INCLUDE_DIR}
  ${QCA_INCLUDE_DIR}
)
INCLUDE_DIRECTORIES(
  ../../core
  ../../gui
  ../../gui/auth
  ../../ui
  ${CMAKE_CURRENT_BINARY_DIR}/../../ui
)

ADD_LIBRARY (postgresprovider MODULE ${PG_SRCS} ${PG_HDRS} ${PG_MOC_SRCS})

TARGET_LINK_LIBRARIES (postgresprovider
  ${POSTGRES_LIBRARY}
  qgis_core
  qgis_gui
)


########################################################
# Install

INSTALL(TARGETS postgresprovider
  RUNTIME DESTINATION ${QGIS_PLUGIN_DIR}
  LIBRARY DESTINATION ${QGIS_PLUGIN_DIR})
