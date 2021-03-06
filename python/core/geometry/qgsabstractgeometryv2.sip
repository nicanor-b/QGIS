struct QgsVertexId
{
%TypeHeaderCode
#include <qgsabstractgeometryv2.h>
%End

    enum VertexType
    {
      SegmentVertex, //start / endpoint of a segment
      CurveVertex
    };

  QgsVertexId();
  QgsVertexId( int _part, int _ring, int _vertex, VertexType _type);

  bool isValid() const;
  bool operator==( const QgsVertexId& other ) const;
  bool operator!=( const QgsVertexId& other ) const;
  bool partEqual( const QgsVertexId& o ) const;
  bool ringEqual( const QgsVertexId& o ) const;
  bool vertexEqual( const QgsVertexId& o ) const;
  bool isValid(const QgsAbstractGeometryV2* geom) const;

  int part;
  int ring;
  int vertex;
  VertexType type;
};

class QgsAbstractGeometryV2
{
%TypeHeaderCode
#include <qgsabstractgeometryv2.h>
#include <qgslinestringv2.h>
%End

%ConvertToSubClassCode
      if (dynamic_cast<QgsPointV2*>(sipCpp) != NULL)
        sipType = sipType_QgsPointV2;
      else if (dynamic_cast<QgsLineStringV2*>(sipCpp) != NULL )
        sipType = sipType_QgsLineStringV2;
      else if (dynamic_cast<QgsCircularStringV2*>(sipCpp) != NULL )
        sipType = sipType_QgsCircularStringV2;
      else if (dynamic_cast<QgsCompoundCurveV2*>(sipCpp) != NULL )
        sipType = sipType_QgsCompoundCurveV2;
      else if (dynamic_cast<QgsPolygonV2*>(sipCpp) != NULL )
        sipType = sipType_QgsPolygonV2;
      else if (dynamic_cast<QgsCurvePolygonV2*>(sipCpp) != NULL )
        sipType = sipType_QgsCurvePolygonV2;
      else if (dynamic_cast<QgsMultiPointV2*>(sipCpp) != NULL )
        sipType = sipType_QgsMultiPointV2;
      else if (dynamic_cast<QgsMultiLineStringV2*>(sipCpp) != NULL )
        sipType = sipType_QgsMultiLineStringV2;
      else if (dynamic_cast<QgsMultiPolygonV2*>(sipCpp) != NULL )
        sipType = sipType_QgsMultiPolygonV2;
      else if (dynamic_cast<QgsMultiSurfaceV2*>(sipCpp) != NULL )
        sipType = sipType_QgsMultiSurfaceV2;
      else if (dynamic_cast<QgsMultiCurveV2*>(sipCpp) != NULL )
        sipType = sipType_QgsMultiCurveV2;
      else if (dynamic_cast<QgsGeometryCollectionV2*>(sipCpp) != NULL )
        sipType = sipType_QgsGeometryCollectionV2;
      else
        sipType = 0;
%End

    public:

    QgsAbstractGeometryV2();
    virtual ~QgsAbstractGeometryV2();
    QgsAbstractGeometryV2( const QgsAbstractGeometryV2& geom );
    //virtual QgsAbstractGeometryV2& operator=( const QgsAbstractGeometryV2& geom );

    virtual QgsAbstractGeometryV2* clone() const = 0;
    virtual void clear() = 0;

    QgsRectangle boundingBox() const;

    //mm-sql interface
    virtual int dimension() const = 0;
    //virtual int coordDim() const { return mCoordDimension; }
    virtual QString geometryType() const = 0;
    QgsWKBTypes::Type wkbType() const;
    QString wktTypeStr() const;
    bool is3D() const;
    bool isMeasure() const;

    //import
    virtual bool fromWkb( const unsigned char * wkb ) = 0;
    virtual bool fromWkt( const QString& wkt ) = 0;

    //export
    virtual int wkbSize() const = 0;
    virtual unsigned char* asWkb( int& binarySize ) const = 0;
    virtual QString asWkt( int precision = 17 ) const = 0;
    virtual QDomElement asGML2( QDomDocument& doc, int precision = 17, const QString& ns = "gml" ) const = 0;
    virtual QDomElement asGML3( QDomDocument& doc, int precision = 17, const QString& ns = "gml" ) const = 0;
    virtual QString asJSON( int precision = 17 ) const = 0;

    virtual QgsRectangle calculateBoundingBox() const;

    //render pipeline
    virtual void transform( const QgsCoordinateTransform& ct, QgsCoordinateTransform::TransformDirection d = QgsCoordinateTransform::ForwardTransform ) = 0;
    virtual void transform( const QTransform& t ) = 0;
    //virtual void clip( const QgsRectangle& rect );
    virtual void draw( QPainter& p ) const = 0;

    /** Returns next vertex id and coordinates
    @return false if at end*/
    virtual bool nextVertex( QgsVertexId& id, QgsPointV2& vertex ) const = 0;

    virtual void coordinateSequence( QList< QList< QList< QgsPointV2 > > >& coord /Out/ ) const = 0;
    int nCoordinates() const;
    virtual QgsPointV2 vertexAt( const QgsVertexId& id ) const = 0;

    /** Searches for the closest segment of the geometry to a given point.
     * @param pt specifies the point to find closest segment to
     * @param segmentPt storage for the closest point within the geometry
     * @param vertexAfter storage for the ID of the vertex at the end of the closest segment
     * @param leftOf returns whether the point lies on the left side of the nearest segment (true if point is to left of segment,
     * false if point is to right of segment)
     * @param epsilon epsilon for segment snapping
     * @returns squared distance to closest segment
     */
    virtual double closestSegment( const QgsPointV2& pt, QgsPointV2& segmentPt,  QgsVertexId& vertexAfter, bool* leftOf, double epsilon ) const = 0;

    //low-level editing
    virtual bool insertVertex( const QgsVertexId& position, const QgsPointV2& vertex ) = 0;
    virtual bool moveVertex( const QgsVertexId& position, const QgsPointV2& newPos ) = 0;
    virtual bool deleteVertex( const QgsVertexId& position ) = 0;

    /** Returns the length of the geometry.
     * @see area()
     * @see perimeter()
     */
    virtual double length() const;

    /** Returns the perimeter of the geometry.
     * @see area()
     * @see length()
     */
    virtual double perimeter() const;

    /** Returns the area of the geometry.
     * @see length()
     * @see perimeter()
     */
    virtual double area() const;

    /** Returns the centroid of the geometry*/
    virtual QgsPointV2 centroid() const;

    /** Returns true if the geometry is empty
     */
    bool isEmpty() const;

    virtual bool hasCurvedSegments() const;
    /** Returns a geometry without curves. Caller takes ownership*/
    virtual QgsAbstractGeometryV2* segmentize() const /Factory/;

    /** Returns approximate angle at a vertex. This is usually the average angle between adjacent
     * segments, and can be pictured as the orientation of a line following the curvature of the
     * geometry at the specified vertex.
     * @param vertex the vertex id
     * @return rotation in radians, clockwise from north
    */
    virtual double vertexAngle( const QgsVertexId& vertex ) const = 0;

    virtual int vertexCount(int part = 0, int ring = 0) const = 0;
    virtual int ringCount(int part = 0) const = 0;
    virtual int partCount() const = 0;

    /** Adds a z-dimension to the geometry, initialized to a preset value.
     * @param zValue initial z-value for all nodes
     * @returns true on success
     * @note added in QGIS 2.12
     * @see addMValue
     */
    virtual bool addZValue( double zValue = 0 ) = 0;

    /** Adds a measure to the geometry, initialized to a preset value.
     * @param mValue initial m-value for all nodes
     * @returns true on success
     * @note added in QGIS 2.12
     * @see addZValue
     */
    virtual bool addMValue( double mValue = 0 ) = 0;

  protected:

    /** Updates the geometry type based on whether sub geometries contain z or m values.
     */
    void setZMTypeFromSubGeometry( const QgsAbstractGeometryV2* subggeom, QgsWKBTypes::Type baseGeomType );

    /** Reads a WKB header and tests its validity.
     * @param wkbPtr
     * @param wkbType destination for WKB type from header
     * @param endianSwap will be set to true if endian from WKB must be swapped to match QGIS platform endianness
     * @param expectedType expected WKB type
     * @returns true if header is valid and matches expected type
     * @note not available in Python bindings
     */
    //static bool readWkbHeader( QgsConstWkbPtr& wkbPtr, QgsWKBTypes::Type& wkbType, bool& endianSwap, QgsWKBTypes::Type expectedType );

};
