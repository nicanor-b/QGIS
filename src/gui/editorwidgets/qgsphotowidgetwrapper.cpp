/***************************************************************************
    qgsphotowidgetwrapper.cpp
     --------------------------------------
    Date                 : 5.1.2014
    Copyright            : (C) 2014 Matthias Kuhn
    Email                : matthias at opengis dot ch
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "qgsphotowidgetwrapper.h"
#include "qgspixmaplabel.h"
#include "qgsproject.h"

#include <QGridLayout>
#include <QFileDialog>
#include <QSettings>

#include "qgsfilterlineedit.h"

QgsPhotoWidgetWrapper::QgsPhotoWidgetWrapper( QgsVectorLayer* vl, int fieldIdx, QWidget* editor, QWidget* parent )
    :  QgsEditorWidgetWrapper( vl, fieldIdx, editor, parent )
    , mPhotoLabel( 0 )
    , mPhotoPixmapLabel( 0 )
    , mLineEdit( 0 )
    , mButton( 0 )
{
#ifdef WITH_QTWEBKIT
  mWebView = 0;
#endif
}

void QgsPhotoWidgetWrapper::selectFileName()
{
  if ( !mLineEdit )
    return;

  QString fileName = QFileDialog::getOpenFileName( 0, tr( "Select a picture" ), QFileInfo( mLineEdit->text() ).absolutePath() );

  if ( fileName.isNull() )
    return;

  QString projPath = QDir::toNativeSeparators( QDir::cleanPath( QgsProject::instance()->fileInfo().absolutePath() ) );
  QString filePath = QDir::toNativeSeparators( QDir::cleanPath( QFileInfo( fileName ).absoluteFilePath() ) );

  if ( filePath.startsWith( projPath ) )
    filePath = QDir( projPath ).relativeFilePath( filePath );

  mLineEdit->setText( filePath );
}

void QgsPhotoWidgetWrapper::loadPixmap( const QString& fileName )
{
  QString filePath = fileName;

  if ( QUrl( fileName ).isRelative() )
    filePath = QDir( QgsProject::instance()->fileInfo().absolutePath() ).filePath( fileName );

#ifdef WITH_QTWEBKIT
  if ( mWebView )
  {
    mWebView->setUrl( filePath );
  }
#endif

  QPixmap pm( filePath );
  if ( !pm.isNull() && mPhotoLabel )
  {
    QSize size( config( "Width" ).toInt(), config( "Height" ).toInt() );
    if ( size.width() == 0 && size.height() > 0 )
    {
      size.setWidth( size.height() * pm.size().width() / pm.size().height() );
    }
    else if ( size.width() > 0 && size.height() == 0 )
    {
      size.setHeight( size.width() * pm.size().height() / pm.size().width() );
    }

    if ( mPhotoPixmapLabel )
    {
      mPhotoPixmapLabel->setPixmap( pm );

      if ( size.width() != 0 || size.height() != 0 )
      {
        mPhotoPixmapLabel->setMinimumSize( size );
        mPhotoPixmapLabel->setMaximumSize( size );
      }
    }
    else // mPhotoLabel is checked in the outer if branch
    {
      mPhotoLabel->setMinimumSize( size );
      pm = pm.scaled( size, Qt::KeepAspectRatio, Qt::SmoothTransformation );
      mPhotoLabel->setPixmap( pm );
    }
  }
}

QVariant QgsPhotoWidgetWrapper::value() const
{
  QVariant v;

  if ( mLineEdit )
  {
    if ( mLineEdit->text() == QSettings().value( "qgis/nullValue", "NULL" ).toString() )
      v = QVariant( QVariant::String );
    else
      v = mLineEdit->text();
  }

  return v;
}

QWidget* QgsPhotoWidgetWrapper::createWidget( QWidget* parent )
{
  QWidget* container = new QWidget( parent );
  QGridLayout* layout = new QGridLayout( container );
  QgsFilterLineEdit* le = new QgsFilterLineEdit( container );
  QgsPixmapLabel* label = new QgsPixmapLabel( parent );
  label->setObjectName( "PhotoLabel" );
  QPushButton* pb = new QPushButton( tr( "..." ), container );
  pb->setObjectName( "FileChooserButton" );

  layout->addWidget( label, 0, 0, 1, 2 );
  layout->addWidget( le, 1, 0 );
  layout->addWidget( pb, 1, 1 );

  container->setLayout( layout );

  return container;
}

void QgsPhotoWidgetWrapper::initWidget( QWidget* editor )
{
  QWidget* container;

  mLineEdit = qobject_cast<QLineEdit*>( editor );
#ifdef WITH_QTWEBKIT
  mWebView = qobject_cast<QWebView*>( editor );
#endif

  if ( mLineEdit )
  {
    container = mLineEdit->parentWidget();
  }
#ifdef WITH_QTWEBKIT
  else if ( mWebView )
  {
    container = mWebView->parentWidget();
    mLineEdit = container->findChild<QLineEdit*>();
  }
#endif
  else
  {
    container = editor;
    mLineEdit = container->findChild<QLineEdit*>();
  }

  mButton = container->findChild<QPushButton*>( "FileChooserButton" );
  if ( !mButton )
    mButton = container->findChild<QPushButton*>();

  mPhotoLabel = container->findChild<QLabel*>( "PhotoLabel" );
  if ( !mPhotoLabel )
    mPhotoLabel = container->findChild<QLabel*>();

  mPhotoPixmapLabel = qobject_cast<QgsPixmapLabel*>( mPhotoLabel );
  if ( mButton )
    connect( mButton, SIGNAL( clicked() ), this, SLOT( selectFileName() ) );

  if ( mLineEdit )
  {

    QgsFilterLineEdit *fle = qobject_cast<QgsFilterLineEdit*>( mLineEdit );
    if ( fle )
    {
      fle->setNullValue( QSettings().value( "qgis/nullValue", "NULL" ).toString() );
    }

    connect( mLineEdit, SIGNAL( textChanged( QString ) ), this, SLOT( valueChanged( QString ) ) );
    connect( mLineEdit, SIGNAL( textChanged( QString ) ), this, SLOT( loadPixmap( QString ) ) );
  }
}

bool QgsPhotoWidgetWrapper::valid() const
{
#ifdef WITH_QTWEBKIT
  return mPhotoLabel || mLineEdit || mButton || mWebView;
#else
  return mPhotoLabel || mLineEdit || mButton;
#endif
}

void QgsPhotoWidgetWrapper::setValue( const QVariant& value )
{
  if ( mLineEdit )
  {
    if ( value.isNull() )
      mLineEdit->setText( QSettings().value( "qgis/nullValue", "NULL" ).toString() );
    else
      mLineEdit->setText( value.toString() );
  }
  else
  {
    loadPixmap( value.toString() );
  }
}

void QgsPhotoWidgetWrapper::setEnabled( bool enabled )
{
  if ( mLineEdit )
    mLineEdit->setEnabled( enabled );

  if ( mButton )
    mButton->setEnabled( enabled );
}
