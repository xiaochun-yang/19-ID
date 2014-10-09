#include <stdio.h>
#include <math.h>
#include <float.h>
#include "matrix.h"
#include "linearRegression.h"

//#define INCLUDE_EDGE 1
static LinearRegression myEngine;

DcsMatrix::DcsMatrix( ): m_numRow(0)
, m_numColumn(0)
, m_pData(NULL)
, m_pValidValue(NULL)
, m_anyData(false)
, m_DataSize(0)
, m_valueMin(DBL_MAX)
, m_valueMax(-DBL_MAX)
, m_pVHitTable(NULL)
, m_VHitSize(0)
, m_pHHitTable(NULL)
, m_HHitSize(0)
{
}

DcsMatrix::~DcsMatrix( )
{
    if (m_pData) delete [] m_pData;
    if (m_pValidValue) delete [] m_pValidValue;
    if (m_pVHitTable) delete [] m_pVHitTable;
    if (m_pHHitTable) delete [] m_pHHitTable;
}

int DcsMatrix::setup( int numRow, int numColumn )
{
    m_numRow = 0;
    m_numColumn = 0;
    m_anyData = false;
    //check input
    if (numRow < 1 || numColumn < 1) {
        printf( "DcsMatrix::setup: bad inputs %d %d\n", numRow, numColumn );
        return 0;
    }

    //allocate memory if needed
    size_t needDataSize = numRow * numColumn;
    if (m_DataSize < needDataSize)
    {
        //re-allocate the buffer
        m_DataSize = 0;
        if (m_pData) delete [] m_pData;
        m_pData = NULL;
        if (m_pValidValue) delete [] m_pValidValue;
        m_pValidValue = NULL;
        m_pData = new double[needDataSize];
        if (!m_pData)
        {
            printf( "no memory for DcsMatrix::setup" );
            return 0;
        }
        m_pValidValue = new char[needDataSize];
        if (!m_pValidValue)
        {
            delete [] m_pData;
            m_pData = NULL;
            printf( "no memory for DcsMatrix::setup" );
            return 0;
        }
        m_DataSize = needDataSize;
    }
    memset( m_pData, 0, sizeof(*m_pData) * m_DataSize );
    memset( m_pValidValue, 0, sizeof(*m_pValidValue) * m_DataSize );

    size_t needVHitSize = (numRow - 1) * numColumn;
    if (m_VHitSize < needVHitSize)
    {
        //re-allocate the buffer
        m_VHitSize = 0;
        if (m_pVHitTable) delete [] m_pVHitTable;
        m_pVHitTable = new signed char[needVHitSize];
        if (!m_pVHitTable)
        {
            printf( "no memory for DcsMatrix::setup" );
            return 0;
        }
        m_VHitSize = needVHitSize;
    }
    memset( m_pVHitTable, 0, sizeof(*m_pVHitTable) * m_VHitSize );
    
    size_t needHHitSize = numRow * (numColumn - 1);
    if (m_HHitSize < needHHitSize)
    {
        //re-allocate the buffer
        m_HHitSize = 0;
        if (m_pHHitTable) delete [] m_pHHitTable;
        m_pHHitTable = new signed char[needHHitSize];
        if (!m_pHHitTable)
        {
            printf( "no memory for DcsMatrix::setup" );
            return 0;
        }
        m_HHitSize = needHHitSize;
    }
    memset( m_pHHitTable, 0, sizeof(*m_pHHitTable) * m_HHitSize );

    //OK
    m_numRow = numRow;
    m_numColumn = numColumn;
    m_valueMin = DBL_MAX;
    m_valueMax = -DBL_MAX;
    //printf( "new numrow %d numcolumn %d\n", m_numRow, m_numColumn );
    return 1;
}
void DcsMatrix::reset( ) {
    memset( m_pData, 0, sizeof(*m_pData) * m_DataSize );
    memset( m_pValidValue, 0, sizeof(*m_pValidValue) * m_DataSize );
    memset( m_pVHitTable, 0, sizeof(*m_pVHitTable) * m_VHitSize );
    memset( m_pHHitTable, 0, sizeof(*m_pHHitTable) * m_HHitSize );
    m_valueMin = DBL_MAX;
    m_valueMax = -DBL_MAX;
    m_anyData = false;
}

//return
// 1:  OK, max min not changed
// 0:  failed
// -1: OK, max min changed

int DcsMatrix::putValue( int row, int column, double value )
{
    //check input range
    if (row < 0 || row >= m_numRow || column < 0 || column >= m_numColumn)
    {
        fprintf( stderr, "DcsMatrix::putValue: bad row %d or column %d\n", row, column );
        fprintf( stderr, "numrow %d numcolumn %d\n", m_numRow, m_numColumn );
        return 0;
    }

    //check state: whether that position already has value
    int data_index = toDataIndex( row, column );
    return putValue( data_index, value );
}
int DcsMatrix::putValue( int data_index, double value )
{
    if (data_index < 0 || data_index >= m_numRow * m_numColumn) {
        fprintf( stderr, "index =%d bad\n", data_index );
        fprintf( stderr, "row=%d col=%d\n", m_numRow, m_numColumn );
        return 0;
    }

    //printf( "DEBUG: data_index=%d\n", data_index );
    if (m_pValidValue[data_index] == -1)
    {
        fprintf( stderr, "DcsMatrix::putValue: (%d) already has value %lf, %lf ignored\n",
                 data_index, m_pData[data_index], value );
        return 1;
    }

    //OK, save the value
    m_pData[data_index] = value;
    m_pValidValue[data_index] = -1;
    m_anyData = true;

    int result = 1;
    if (value < m_valueMin)
    {
        m_valueMin = value;
        result = -1;
    }
    if (value > m_valueMax)
    {
        m_valueMax = value;
        result = -1;
    }
    return result;
}

//return
// -1:  OK
// 0 :  failed

int DcsMatrix::setValues( int len, const double values[] )
{
    reset( );

    //check input range
    if (len < 0 || len > m_numRow * m_numColumn) {
        fprintf( stderr, "DcsMatrix::setValues: bad len=%d\n", len );
        fprintf( stderr, "numrow %d numcolumn %d\n", m_numRow, m_numColumn );
        return 0;
    }


    int i = 0;
    for (i = 0; i < len; ++i) {
        if (values[i] == INFINITY) {
            //printf("got INF at %d\n", i );
            continue;
        }
        m_pData[i] = values[i];
        m_pValidValue[i] = -1;
        m_anyData = true;

        if (m_valueMin > values[i]) {
            m_valueMin = values[i];
        }
        if (m_valueMax < values[i]) {
            m_valueMax = values[i];
        }
    }
    return -1;
}

int DcsMatrix::getValue( int row, int column, double& value ) const
{
    //check input range
    if (row < 0 || row >= m_numRow || column < 0 || column >= m_numColumn)
    {
        fprintf( stderr, "DcsMatrix::getValue: bad row %d or column %d\n", row, column );
        return 0;
    }
    //check state: whether that position already has value
    int data_index = toDataIndex( row, column );
    if (m_pValidValue[data_index] != -1)
    {
        return 0;
    }

    //OK
    value = m_pData[data_index];
    return 1;
}

void DcsMatrix::findHit( double level ) const
{
    int previous_plus(0);
    int row;
    int col;

#if 0
    for (row = 0; row < m_numRow; ++row)
    {
        for (col = 0; col < m_numColumn; ++col)
        {
            int data_index = toDataIndex( row, col );
            if (m_pData[data_index] > level)
            {
                printf( "+" );
            }
            else
            {
                printf( "-" );
            }
        }
        printf( "\n" );
    }
#endif

    //clear tables
    memset( m_pVHitTable, 0, sizeof(*m_pVHitTable) * m_VHitSize );
    memset( m_pHHitTable, 0, sizeof(*m_pHHitTable) * m_HHitSize );

    //V hit
    for (col = 0; col < m_numColumn; ++col)
    {
        int data_index = toDataIndex( 0, col );
        previous_plus = (m_pData[data_index] > level) ? 1 : 0;
        for (row = 1; row < m_numRow; ++row)
        {
            data_index = toDataIndex( row, col );
            int V_index = toVHitIndex( row - 1, col );
            if (previous_plus && m_pData[data_index] <= level)
            {
                m_pVHitTable[V_index] = -1;
                previous_plus = 0;
            }
            else if (!previous_plus && m_pData[data_index] > level)
            {
                m_pVHitTable[V_index] = 1;
                previous_plus = 1;
            }
        }
    }
    //hit H
    for (row = 0; row < m_numRow; ++row)
    {
        int data_index = toDataIndex( row, 0 );
        previous_plus = (m_pData[data_index] > level) ? 1 : 0;
        for (col = 1; col < m_numColumn; ++col)
        {
            data_index = toDataIndex( row, col );
            int H_index = toHHitIndex( row, col - 1 );
            if (previous_plus && m_pData[data_index] <= level)
            {
                m_pHHitTable[H_index] = -1;
                previous_plus = 0;
            }
            else if (!previous_plus && m_pData[data_index] > level)
            {
                m_pHHitTable[H_index] = 1;
                previous_plus = 1;
            }
        }
    }

    //clear hit around not-defined point
    for (row = 0; row < m_numRow; ++row)
    {
        for (col = 0; col < m_numColumn; ++col)
        {
            int data_index = toDataIndex( row, col );
            if (m_pValidValue[data_index] == 1) {
                if (row != m_numRow  - 1) {
                    int V_index = toVHitIndex( row, col );
                    m_pVHitTable[V_index] *= 2;
                }
                if (row > 0) {
                    int V_index = toVHitIndex( row - 1, col );
                    m_pVHitTable[V_index] *= 2;
                }
                if (col != m_numColumn - 1) {
                    int H_index = toHHitIndex( row, col );
                    m_pHHitTable[H_index] *= 2;
                }
                if (col > 0) {
                    int H_index = toHHitIndex( row, col - 1 );
                    m_pHHitTable[H_index] *= 2;
                }
            }
        }
    }
}

int DcsMatrix::find_next_move( int& next_row, int& next_col, Direction& next_move ) const
{
    int current_row(next_row);
    int current_col(next_col);
    Direction current_move(next_move);
    int left_col(0);
    int right_col(0);
    int upper_row(0);
    int lower_row(0);

    getNeighbor( current_move, current_row, current_col,
        left_col, right_col, upper_row, lower_row );
    
    switch (current_move)
    {
    case LEFT:
        if (left_col < 0) return 0;
        if (HHit( upper_row, left_col ))
        {
            next_move = UP;
        }
        else if (HHit( lower_row, left_col ))
        {
            next_move = DOWN;
        }
        else
        {
            next_move = LEFT;
        }
        break;

    case RIGHT:
        if (right_col >= m_numColumn) return 0;
        if (HHit( lower_row, left_col ))
        {
            next_move = DOWN;
        }
        else if (HHit( upper_row, left_col ))
        {
            next_move = UP;
        }
        else
        {
            next_move = RIGHT;
        }
        break;

    case UP:
        if (upper_row >= m_numRow) return 0;
        if (VHit( lower_row, right_col ))
        {
            next_move = RIGHT;
        }
        else if (VHit( lower_row, left_col ))
        {
            next_move = LEFT;
        }
        else
        {
            next_move = UP;
        }
        break;

    case DOWN:
        if (lower_row < 0) return 0;
        if (VHit( lower_row, left_col ))
        {
            next_move = LEFT;
        }
        else if (VHit( lower_row, right_col ))
        {
            next_move = RIGHT;
        }
        else
        {
            next_move = DOWN;
        }
    }

    switch (next_move)
    {
    case LEFT:
        next_row = lower_row;
        next_col = left_col;
        break;

    case RIGHT:
        next_row = lower_row;
        next_col = right_col;
        break;

    case UP:
        next_row = upper_row;
        next_col = left_col;
        break;

    case DOWN:
        next_row = lower_row;
        next_col = left_col;
        break;
    }
    return 1;
}

// x[], y[] and length are INPUT/OUTPUT
void DcsMatrix::find_segment( double level, int maxLength, bool startVertical, int startRow, int startCol, double x[], double y[], int& length ) const
{
    Direction next_move(UP);
    int col(0);
    int row(0);
    double current_x(0);
    double current_y(0);

    //printf("+find_segment: maxL: %d, already have: %d start(%d,%d) V?(%d)\n", maxLength, length, startRow, startCol, (int)startVertical );

    //check input
    if (length >= maxLength)
    {
        printf( "DcsMatrax::find_segment: array already full" );
        return;
    }
    //double check if the start position is a hit
    if (startVertical)
    {
        if (!VHit( startRow, startCol ))
        {
            printf( "[%d %d] is not vertical hit", startRow, startCol );
            return;
        }
    }
    else
    {
        if (!HHit( startRow, startCol ))
        {
            printf( "[%d %d] is not vertical hit", startRow, startCol );
            return;
        }
    }

    //get start point
    col = startCol;
    row = startRow;
    if (startVertical)
    {
        //next move direction
        next_move = (VHit( row, col ) == 1) ? LEFT : RIGHT;

        //find the contour cross the column position
        getCrossVertPosition( row, col, level, current_x, current_y );
    }
    else
    {
        //next move direction
        next_move = (HHit( row, col ) == 1) ? UP : DOWN;

        //find the contour cross the column position
        getCrossHorzPosition( row, col, level, current_x, current_y );
    }
    //save this start point
    //printf( "add (%lf, %lf) at %d\n", current_x, current_y, length );
    x[length] = current_x;
    y[length] = current_y;
    ++length;
    if (length >= maxLength)
    {
        printf( "array already full before find_seg" );
        return;
    }

    //////////////////big loop//////////////
    while (1)
    {
        //find next move
#ifdef INCLUDE_EDGE
        if (!find_next_move( row, col, next_move)
        && !traceEdge( row, col, next_move, x, y, length, maxLength)) {
            return;
        }
#else
        if (!find_next_move( row, col, next_move))
        {
            //printf( "no more move" );
            return;
        }
#endif
        switch (next_move)
        {
        case LEFT:
        case RIGHT:
            //clear flag
            if (!(m_pVHitTable[toVHitIndex( row, col )] % 2)) {
                return;
            }
            m_pVHitTable[toVHitIndex( row, col )] = 0;
            //calculate
            getCrossVertPosition( row, col, level, current_x, current_y );
            break;

        case UP:
        case DOWN:
            //clear flag
            if (!(m_pHHitTable[toHHitIndex( row, col )] % 2)) {
                return;
            }

            m_pHHitTable[toHHitIndex( row, col )] = 0;
            //calculate
            getCrossHorzPosition( row, col, level, current_x, current_y );
        }
        //printf( "add (%lf, %lf) at %d\n", current_x, current_y, length );
        x[length] = current_x;
        y[length] = current_y;
        ++length;
        if (length >= maxLength)
        {
            printf( "array full during walk contour" );
            return;
        }

        // check circle
        if (row == startRow && col == startCol)
        {
            switch (next_move)
            {
            case LEFT:
            case RIGHT:
                if (startVertical) return;
                break;

            case UP:
            case DOWN:
                if (!startVertical) return;
            }
        }
    }//while(1) big loop
    //printf("-find_segment: new length%d\n", maxLength, length );
}

#define ADD_SEGMENT                             \
segments[num_segment].m_length = length - segments[num_segment].m_offset; \
if (segments[num_segment].m_length > 0)         \
{                                               \
    ++num_segment;                              \
    if (num_segment >= maxSegment)              \
    {                                           \
        return num_segment;                     \
    }                                           \
    segments[num_segment].m_offset = length;    \
}

int DcsMatrix::allDataDefined( ) const
{
    for (int row = 0; row < m_numRow; ++row)
    {
        for (int col = 0; col < m_numColumn; ++col)
        {
            if (!m_pValidValue[toDataIndex( row, col )])
            {
                printf( "data[%d,%d] not defined\n", row, col );
                return 0;
            }
        }
    }
    return 1;
}

int DcsMatrix::getContour( double relative_level, int maxLength, double x[], double y[], int& length, int maxSegment, DcsContourSegment segments[] ) const
{
    int num_segment(0);
    int row(0);
    int col(0);
    double level(0);

    length = 0;
    //check input
    if (relative_level < 0.0 || relative_level >= 1.0)
    {
        return num_segment;
    }
    if (maxLength < 2 || x == NULL || y == NULL)
    {
        return num_segment;
    }
    if (maxSegment < 1)
    {
        return num_segment;
    }
    if (m_valueMax == m_valueMin)
    {
        printf( "max==min=%f, contour skipped\n", m_valueMin );
        return num_segment;
    }
    ///////////check: all values must be set/////////////
    if (!allDataDefined( ))
    {
        return num_segment;
    }

    level = m_valueMin + (m_valueMax - m_valueMin) * relative_level;
    ///////// fill hit tables
    //printf( "real level: %lf\n", level );
    findHit( level );

    //printf("in start get contour\n");
    //printHitTable( );

    //find contour segments
    //do open curves at edges first
    //bottom
    segments[num_segment].m_offset = length;
    for (col = 0; col < m_numColumn - 1; ++col)
    {
        if (HHit( 0, col ) == 1)
        {
            find_segment( level, maxLength, false, 0, col, x, y, length );
            m_pHHitTable[toHHitIndex( 0, col )] = 0;
            ADD_SEGMENT;
        }
    }

    //top
    int topRow = m_numRow - 1;
    for (col = 0; col < m_numColumn - 1; ++col)
    {
        if (HHit( topRow, col ) == -1)
        {
            find_segment( level, maxLength, false, topRow, col, x, y, length );
            m_pHHitTable[toHHitIndex( topRow, col )] = 0;
            ADD_SEGMENT;
        }
    }

    //left
    for (row = 0; row < m_numRow - 1; ++row)
    {
        if (VHit( row, 0 ) == -1)
        {
            find_segment( level, maxLength, true, row, 0, x, y, length );
            m_pVHitTable[toVHitIndex( row, 0 )] = 0;
            ADD_SEGMENT;
        }
    }

    //right
    int edge_col = m_numColumn - 1;
    for (row = 0; row < m_numRow - 1; ++row)
    {
        if (VHit( row, edge_col ) == 1)
        {
            find_segment( level, maxLength, true, row, edge_col, x, y, length );
            m_pVHitTable[toVHitIndex( row, edge_col)] = 0;
            ADD_SEGMENT;
        }
    }

    /////////// all inside circles ////////////
    for (row = 1; row < m_numRow - 1; ++row)
    {
        for (col = 0; col < m_numColumn - 1; ++col)
        {
            if (HHit( row, col ) == 1 || HHit( row, col ) == -1)
            {
                find_segment( level, maxLength, false, row, col, x, y, length );
                ADD_SEGMENT;
            }
        }
    }//for row

    for (col = 1; col < m_numColumn - 1; ++col)
    {
        for (row = 0; row < m_numRow - 1; ++row)
        {
            if (VHit( row, col ) == 1 || VHit( row, col ) == -1)
            {
                find_segment( level, maxLength, true, row, col, x, y, length );
                ADD_SEGMENT;
            }
        }
    }
    //printf("at the end of get contour\n");
    //printHitTable( );

#if 0
    for (int i = 0; i < num_segment; ++i)
    {
        printf( "seg[%d] offset: %d, length %d\n", i, segments[i].m_offset, segments[i].m_length );
    }
#endif
    
    return num_segment;
}

int DcsMatrix::getRidge( double relative_level,
        vector<vector<RidgeNode> > &ridges ) const {
    int row(0);
    int col(0);
    double level(0);

    ridges.clear( );

    //check input
    if (relative_level < 0.0 || relative_level >= 1.0)
    {
        return 0;
    }
    if (m_valueMax == m_valueMin)
    {
        printf( "max==min=%f, ridge skipped\n", m_valueMin );
        return 0;
    }
    ///////////check: all values must be set/////////////
    if (!allDataDefined( ))
    {
        return 0;
    }

    level = m_valueMin + (m_valueMax - m_valueMin) * relative_level;
    //printf( "real level: %lf\n", level );
    findRidgeMark( level );

    for (col = 0; col < m_numColumn; ++col) {
        for (row = 0; row < m_numRow; ++row) {
            if (m_ridgeMark[row][col]) {
                //traceOneRidgeWithWeight( row, col, ridges, level );
                traceOneRidgeWithGeo( row, col, ridges, level );
            }
        }
    }
    
    return ridges.size( );
}
int DcsMatrix::traceOneRidgeWithWeight( int start_row, int start_col,
vector<vector<RidgeNode> > &ridges, double level ) const {

    printf( "traceOneRidgeWithWeight start from row: %d col: %d\n",
        start_row, start_col );

    //double check
    if (!m_ridgeMark[start_row][start_col]) {
        return 0;
    }

    vector<RidgeNode> oneRidge;
    int col;

    //Add an extra starting point with weight = 0, so that it will not be used
    //in the fit but will be used as starting x for the line.
    //The purpose is to try to get very close to the contour line.
    if (start_col != 0) {
        double startX = 1;
        int    theRow = -1;
        printf( "check extra starting point, from row=%d\n", start_row );
        for (int row = start_row; row < m_numRow; ++row) {
            if (!m_ridgeMark[row][start_col]) {
                break;
            }
            int data_index0 = toDataIndex( row, start_col - 1 );
            int data_index1 = toDataIndex( row, start_col );
            double v0 = m_pData[data_index0];
            double v1 = m_pData[data_index1];
            double extra = (level - v0)/ (v1 - v0);
            printf( "for row=%d v0=%f v1=%f extra=%f\n", row, v0, v1, extra );
            if (extra < startX) {
                startX = extra;
                if (startX < 0) {
                    startX  = 0;
                    printf( "LOGICAL ERROR for start\n" );
                }
                theRow = row;
                printf( "moving startX to %f\n", startX );
            }
        }
        if (startX < 0.99) {
            double firstX = start_col - 1 + startX;
            oneRidge.push_back( RidgeNode( firstX, theRow, 0 ) );
            printf( "Extra point: %f %d 0\n", firstX, theRow );
        }
    }

    int end_row = start_row;
    for (col = start_col; col < m_numColumn; ++col) {
        double centerRow = 0;
        double maxPeak = 0;
        double weight = 0;   
        for (int row = start_row; row < m_numRow; ++row) {
            if (!m_ridgeMark[row][col]) {
                break;
            }
            end_row = row;
            m_ridgeMark[row][col] = false; //mark we done this node
            double w = m_ridgeAbove[row][col];
            centerRow += row * w;
            weight    += w;
            if (w > maxPeak) {
                maxPeak = w;
            }
        }
        if (weight != 0) {
            centerRow /= weight;
        }
        // change the weight to maxPeak if we decide use that as weight
        printf( "push back: %d %f %f\n", col, centerRow, weight );
        oneRidge.push_back( RidgeNode( col, centerRow, weight ) );
        if (col >= m_numColumn - 1) {
            break;
        }
        //check whether this ridge end:
        //for now, we require that neighbor+-1 row must be marked.
        // from start_row to end_row
        int checkRowStart = start_row;
        int checkRowEnd   = end_row;
        int checkCol      = col + 1;
        if (checkRowStart < 0) {
            checkRowStart = 0;
        }
        if (checkRowEnd >= m_numRow) {
            checkRowEnd = m_numRow - 1;
        }
        int rowFound = -1; //mark no more
        for (int checkRow = checkRowStart; checkRow <= checkRowEnd; ++checkRow) {
            printf( "checking r=%d c=%d\n", checkRow, checkCol );
            if (m_ridgeMark[checkRow][checkCol]) {
                rowFound = checkRow; //next column
                printf( "got it, next col start from row=%d\n", rowFound );
                break;
            }
        }
        if (rowFound < 0) {
            break;
        } else {
            //trace upper to get the startRow
            for (int row = rowFound; row >= 0; -- row) {
                if (m_ridgeMark[row][checkCol]) {
                    start_row = row;
                } else {
                    break;
                }
            }
            //continue next column
        }
    }
    if (col < m_numColumn - 1) {
        double endX = 0;
        int    theRow = -1;
        printf( "check for extra end: col=%d start_row=%d\n", col, start_row );
        for (int row = start_row; row < m_numRow; ++row) {
            int data_index0 = toDataIndex( row, col );
            int data_index1 = toDataIndex( row, col + 1 );
            double v0 = m_pData[data_index0];
            double v1 = m_pData[data_index1];
            //cannot use mark any more, already cleared
            //if (!m_ridgeMark[row][start_col]) {
            //    break;
            //}
            if (v0 < level) {
                break;
            }

            double extra = (level - v0)/ (v1 - v0);
            if (extra > endX) {
                endX = extra;
                theRow = row;
                printf( "moving endX to %f\n", endX );
            }
        }
        if (endX > 0.01) {
            double lastX = col + endX;
            oneRidge.push_back( RidgeNode( lastX, theRow, 0 ) );
            printf( "Extra point: %f %d 0\n", lastX, theRow );
        }
    }

    if (oneRidge.size( ) > 0) {
        printf( "ADD RIDGE size=%d\n", oneRidge.size( ) );
        ridges.push_back( oneRidge );
    }
    return oneRidge.size( );
}

int DcsMatrix::traceOneRidgeWithGeo( int start_row, int start_col,
vector<vector<RidgeNode> > &ridges, double level ) const {

    printf( "traceOneRidgeWithGeo start from row: %d col: %d\n",
        start_row, start_col );

    //double check
    if (!m_ridgeMark[start_row][start_col]) {
        return 0;
    }

    vector<RidgeNode> oneRidge;
    int col;

    //Add an extra starting point with weight = 0, so that it will not be used
    //in the fit but will be used as starting x for the line.
    //The purpose is to try to get very close to the contour line.
    if (start_col != 0) {
        double startX = 1;
        int    theRow = -1;
        printf( "check extra starting point, from row=%d\n", start_row );
        for (int row = start_row; row < m_numRow; ++row) {
            if (!m_ridgeMark[row][start_col]) {
                break;
            }
            int data_index0 = toDataIndex( row, start_col - 1 );
            int data_index1 = toDataIndex( row, start_col );
            double v0 = m_pData[data_index0];
            double v1 = m_pData[data_index1];
            double extra = (level - v0)/ (v1 - v0);
            printf( "for row=%d v0=%f v1=%f extra=%f\n", row, v0, v1, extra );
            if (extra < startX) {
                startX = extra;
                if (startX < 0) {
                    startX  = 0;
                    printf( "LOGICAL ERROR for start\n" );
                }
                theRow = row;
                printf( "moving startX to %f\n", startX );
            }
        }
        if (startX < 0.99) {
            double firstX = start_col - 1 + startX;
            oneRidge.push_back( RidgeNode( firstX, theRow, 0 ) );
            printf( "Extra point: %f %d 0\n", firstX, theRow );
        }
    }

    int end_row = start_row;
    for (col = start_col; col < m_numColumn; ++col) {
        double startY = 0;
        double endY = 0;
        double centerRow = 0;
        if (start_row ==0) {
            startY = -0.5;
        } else {
            double dummy;
            getCrossVertPosition( start_row - 1, col, level, dummy, startY );
        }
        printf( "for col=%d startY=%lf\n", col, startY );
        for (int row = start_row; row < m_numRow; ++row) {
            if (!m_ridgeMark[row][col]) {
                break;
            }
            end_row = row;
            m_ridgeMark[row][col] = false; //mark we done this node
        }
        if (end_row == m_numRow - 1) {
            endY = end_row + 0.5;
        } else {
            double dummy;
            getCrossVertPosition( end_row, col, level, dummy, endY );
        }
        printf( "for col=%d endY=%lf\n", col, endY );
        centerRow = (startY + endY) / 2.0;

        printf( "push geo back: %d %f\n", col, centerRow );
        oneRidge.push_back( RidgeNode( col, centerRow, 100 ) );
        if (col >= m_numColumn - 1) {
            break;
        }
        //check whether this ridge end:
        //for now, we require that neighbor row must be marked.
        // from start_row to end_row
        int checkRowStart = start_row;
        int checkRowEnd   = end_row;
        int checkCol      = col + 1;
        if (checkRowStart < 0) {
            checkRowStart = 0;
        }
        if (checkRowEnd >= m_numRow) {
            checkRowEnd = m_numRow - 1;
        }
        int rowFound = -1; //mark no more
        for (int checkRow = checkRowStart; checkRow <= checkRowEnd; ++checkRow) {
            printf( "checking r=%d c=%d\n", checkRow, checkCol );
            if (m_ridgeMark[checkRow][checkCol]) {
                rowFound = checkRow; //next column
                printf( "got it, next col start from row=%d\n", rowFound );
                break;
            }
        }
        if (rowFound < 0) {
            break;
        } else {
            //trace upper to get the startRow
            for (int row = rowFound; row >= 0; -- row) {
                if (m_ridgeMark[row][checkCol]) {
                    start_row = row;
                } else {
                    break;
                }
            }
            //continue next column
        }
    }
    if (col < m_numColumn - 1) {
        double endX = 0;
        int    theRow = -1;
        printf( "check for extra end: col=%d start_row=%d\n", col, start_row );
        for (int row = start_row; row < m_numRow; ++row) {
            int data_index0 = toDataIndex( row, col );
            int data_index1 = toDataIndex( row, col + 1 );
            double v0 = m_pData[data_index0];
            double v1 = m_pData[data_index1];
            //cannot use mark any more, already cleared
            //if (!m_ridgeMark[row][start_col]) {
            //    break;
            //}
            if (v0 < level) {
                break;
            }

            double extra = (level - v0)/ (v1 - v0);
            if (extra > endX) {
                endX = extra;
                theRow = row;
                printf( "moving endX to %f\n", endX );
            }
        }
        if (endX > 0.01) {
            double lastX = col + endX;
            oneRidge.push_back( RidgeNode( lastX, theRow, 0 ) );
            printf( "Extra point: %f %d 0\n", lastX, theRow );
        }
    }

    if (oneRidge.size( ) > 0) {
        printf( "ADD RIDGE size=%d\n", oneRidge.size( ) );
        ridges.push_back( oneRidge );
    }
    return oneRidge.size( );
}

void DcsMatrix::printHitTable( ) const
{
    printf( "======================= MATRIX ======================\n" );
    printf( "numRow = %d, numColumn = %d, value max: %lf min: %lf\n",
                m_numRow, m_numColumn, m_valueMax, m_valueMin );
    printf( "HHHHHHHHHHHHHHHHHHHHHH\n");
    int row;
    int col;
    for (row = 0; row < m_numColumn; ++row)
    {
        for (col = 0; col < m_numRow - 1; ++col)
        {
            switch (HHit( row, col ))
            {
                case 1:
                    printf("+");
                    break;

                case -1:
                    printf("-");
                    break;

                default:
                    printf(" ");
            }
        }
        printf( "\n" );
    }
    printf( "VVVVVVVVVVVVVVVVVVVVVVVV\n");

    for (row = 0; row < m_numRow - 1; ++row)
    {
        for (col = 0; col < m_numColumn; ++col)
        {
            switch (VHit( row, col ))
            {
                case 1:
                    printf("+");
                    break;

                case -1:
                    printf("-");
                    break;

                default:
                    printf(" ");
            }
        }
        printf( "\n" );
    }
}

void DcsMatrix::getRow( int row, int maxLength, double value[], int& length ) const
{
    length = 0;

    //check input range
    if (row < 0 || row >= m_numRow)
    {
        printf( "DcsMatrix::getRow: bad row %d\n", row );
        return;
    }

    int col = 0;

    for (col = 0; col < m_numColumn; ++col)
    {
        int data_index = toDataIndex( row, col );
        if (!m_pValidValue[data_index])
        {
            return;
        }
        value[length++] = m_pData[data_index];
    }
}
void DcsMatrix::getColumn( int column, int maxLength, double value[], int& length ) const
{
    length = 0;

    //check input range
    if (column < 0 || column >= m_numColumn)
    {
        printf( "DcsMatrix::getColumn: bad column %d\n", column );
        return;
    }

    int row = 0;

    for (row = 0; row < m_numRow; ++row)
    {
        int data_index = toDataIndex( row, column );
        if (!m_pValidValue[data_index])
        {
            return;
        }
        value[length++] = m_pData[data_index];
    }
}

void DcsMatrix::setAllUndefinedNodeToMin( )
{
    if (!m_anyData) {
        return;
    }
    for (int row = 0; row < m_numRow; ++row)
    {
        for (int col = 0; col < m_numColumn; ++col)
        {
            int data_index = toDataIndex( row, col );
            if (!m_pValidValue[data_index])
            {
                m_pData[data_index] = m_valueMin;
                m_pValidValue[data_index] = 1;
            }
        }
    }
}
void DcsMatrix::findRidgeMark( double level ) const {
    //resize and clear the mark matrix
    m_ridgeMark.assign( m_numRow, vector<bool>(m_numColumn, false) );
    m_ridgeAbove.assign( m_numRow, vector<double>(m_numColumn, 0) );
    // mark nodes above the cut
    for (int row = 0; row < m_numRow; ++row) {
        for (int col = 0; col < m_numColumn; ++col) {
            int data_index = toDataIndex( row, col );
            if (m_pData[data_index] >= level) {
                m_ridgeMark[row][col] = true;
                m_ridgeAbove[row][col] = m_pData[data_index] - level;
            }
        }
    }
}

DcsScan2DData::DcsScan2DData( ): m_inited(false)
, m_firstRowY(0)
, m_firstColumnX(0)
, m_nodeWidth(1)
, m_nodeHeight(1)
, m_rowPlotHeight(100)
, m_columnPlotWidth(100)
, m_maxColor(255)
, m_rowScale(0)
, m_columnScale(0)
, m_colorScale(0)
, m_rowPlotScale(1)
, m_columnPlotScale(1)
{
}

int DcsScan2DData::setup( int numRow, double firstRowY, double rowStep,
    int numColumn, double firstColumnX, double columnStep, int maxColor
) {
    m_inited = false;
    m_colorScale = 0;
    //call base class setup first to check numRow and numColumn
    if (!DcsMatrix::setup( numRow, numColumn ))
    {
        return 0;
    }

    //check other inputs
    if (rowStep == 0 || columnStep == 0)
    {
        printf( "bad step size\n" );
        return 0;
    }
    if (maxColor < 1)
    {
        printf( "bad max color value\n" );
        return 0;
    }

    //save data
    m_firstRowY = firstRowY;
    m_firstColumnX = firstColumnX;
    m_rowScale    = 1.0 / rowStep;
    m_columnScale = 1.0 / columnStep;
    m_maxColor = maxColor;

    m_inited = true;
    return 1;
}

void DcsScan2DData::reset( ) {
    DcsMatrix::reset( );

    m_colorScale = 0; //flag need to re-calculate
    m_rowPlotScale = 0;
    m_columnPlotScale = 0;
}
int DcsScan2DData::addData( double x, double y, double value )
{
    //check status
    if (!m_inited) return 0;

    int result = putValue( toRow( y ), toColumn( x ), value );
    if (result == -1)
    {
        m_colorScale = 0; //flag need to re-calculate
        m_rowPlotScale = 0;
        m_columnPlotScale = 0;
    }
    return result;
}
int DcsScan2DData::addData( int index, double value )
{
    //check status
    if (!m_inited) return 0;

    int result = putValue( index, value );
    if (result == -1)
    {
        m_colorScale = 0; //flag need to re-calculate
        m_rowPlotScale = 0;
        m_columnPlotScale = 0;
    }
    return result;
}

int DcsScan2DData::getColor( int row, int col ) const
{
    double value(0);
    if (!DcsMatrix::getValue( row, col, value ))
    {
        return -1;
    }
        
    if (value <= m_valueMin) return 0;
    if (value >= m_valueMax) return m_maxColor;
        
    if (m_colorScale == 0)
    {
        //if m_valueMax == m_valueMin, it already return 0 above
        m_colorScale = m_maxColor / (m_valueMax - m_valueMin );
    }

    return int( (value - m_valueMin) * m_colorScale);
}

int DcsScan2DData::getContour( double relative_level, int maxLength, double x[], double y[], int& length, int maxSegment, DcsContourSegment segments[] ) const
{
    int result = DcsMatrix::getContour( relative_level, maxLength, x, y, length, maxSegment, segments );

    //convert units
    for (int i = 0; i < length; ++i)
    {
        //shift (0.5, 0.5) because in our graph, node is in the center of
        // a rectangle
        x[i] += 0.5;
        y[i] += 0.5;

        //scale 
        x[i] *= m_nodeWidth;
        y[i] *= m_nodeHeight;
    }
    return result;
}

//here X, Y are coordinates in canvas, not the same as addData
int DcsScan2DData::getValue( double x, double y, double& value ) const
{
    //check status
    if (!m_inited) return 0;

    int row = int( y / m_nodeHeight );
    int col = int( x / m_nodeWidth );

    if (row < 0) row = 0;
    if (row >= m_numRow) row = m_numRow - 1;

    if (col < 0) col = 0;
    if (col >= m_numColumn) col = m_numColumn - 1;

    return DcsMatrix::getValue( row, col, value );
}

void DcsScan2DData::getRowPlot( double y0, int maxLength, double x[], double y[], int& length ) const
{
    length = 0;
    if (!m_inited) return;
    
    if (m_valueMax == m_valueMin)
    {
        printf( "max==min=%f, row plot skipped\n", m_valueMin );
        return;
    }

    int row = (int)(y0 / m_nodeHeight);

    DcsMatrix::getRow( row, maxLength, y, length );
    if (length <= 0) return;

    if (m_rowPlotScale == 0)
    {
        m_rowPlotScale = m_rowPlotHeight / (m_valueMax - m_valueMin);
    }

    double yOffset = m_nodeHeight * m_numRow;

    for (int i = 0; i < length; ++i)
    {
        y[i] = (y[i] - m_valueMin) * m_rowPlotScale + yOffset;
        x[i] = (0.5 + i) * m_nodeWidth;
    }
}
void DcsScan2DData::getColumnPlot( double x0, int maxLength, double x[], double y[], int& length ) const
{
    length = 0;
    if (!m_inited) return;

    if (m_valueMax == m_valueMin)
    {
        printf( "max==min=%f, column plot skipped\n", m_valueMin );
        return;
    }

    int col = (int)(x0 / m_nodeWidth);
    DcsMatrix::getColumn( col, maxLength, x, length );
    if (length <= 0) return;

    if (m_columnPlotScale == 0)
    {
        m_columnPlotScale = m_columnPlotWidth / (m_valueMax - m_valueMin);
    }

    double xOffset = m_nodeWidth * m_numColumn;

    for (int i = 0; i < length; ++i)
    {
        x[i] = (x[i] - m_valueMin) * m_columnPlotScale + xOffset;
        y[i] = (0.5 + i) * m_nodeWidth;
    }
}

int DcsScan2DData::generateAxis( double start, double end,
                     double& step_size, int& n_start, int& num_marks,
                     AxisStepStyle& step_style )
{
    double delta = end - start;

    if (delta == 0)
    {
        printf( "start==end\n" );
        return 0;
    }

    //init value
    step_size = (delta > 0) ? 1 : -1;
    step_style = STEP_1;

    //reduce num_marks to [10,100)
    num_marks = (int)(delta / step_size + 0.01); //the 0.01 is for error
    while (num_marks < 10)
    {
        step_size /= 10.0;
        num_marks = (int)(delta / step_size + 0.01);
    }
    while (num_marks >= 100)
    {
        step_size *= 10.0;
        num_marks = (int)(delta / step_size + 0.01);
    }

    //printf( "after first run : step_size==%lf, n=%d\n", step_size, num_marks );

    //reduce the num_marks to (5-10]
    if (num_marks > 50)
    {
        step_size *= 10;
        num_marks = (int)(delta / step_size + 0.01);
        step_style = STEP_1;
    }
    else if (num_marks > 20)
    {
        step_size *= 5;
        num_marks = (int)(delta / step_size + 0.01);
        step_style = STEP_5;
    }
    else if (num_marks > 10)
    {
        step_size *= 2;
        num_marks = (int)(delta / step_size + 0.01);
        step_style = STEP_2;
    }

    //printf( "after second run : step_size==%lf, n=%d\n", step_size, num_marks );

    //generate the marks
    n_start = 0;
    n_start = (int)(start / step_size + 0.01);

    int n_end = (int)(end / step_size + 0.01);
    //printf( "n_start=%d n_end=%d\n", n_start, n_end );

    if (n_start + num_marks <= n_end)
    {
        ++num_marks;
        //printf( "incraase num\n" );
    }
    else
    {
        double x1_error = start - step_size * (n_start - 1);

        //printf( "x1_error=%lf\n", x1_error );
        if (x1_error > -0.01 && x1_error < 0.01)
        {
            --n_start;
            ++num_marks;
            //printf( "add start to mark\n" );
        }
    }

    //printf( "step_size=%lf, n_start=%d, num=%d, style=%d\n",
    //    step_size, n_start, num_marks, step_style );

    for (int i = 0; i < num_marks; ++i)
    {
        //printf( "mark[%d]=%lf\n", i, step_size * (i + n_start) );
    }
    return 1;
}
int DcsScan2DData::toColumnRow( double x, double y, int& column, int& row ) const
{
    if (!m_inited) return 0;

    column = toColumn( x );
    row = toRow( y );
    if (row < 0 || row >= m_numRow || column < 0 || column >= m_numColumn)
    {
        return 0;
    }
    return 1;
}
int DcsScan2DData:: getRidge( double relative_level,
        double beamWidth, double beamSpace,
        vector<vector<RidgeNode> > &ridges ) const {

    printf( "getRidge level=%lf, bw=%lf, bs=%lf\n", relative_level,
    beamWidth, beamSpace );

    int result = DcsMatrix::getRidge( relative_level, ridges );
    printf( "2D: got %d ridges from matrix\n", result );
    vector<vector<RidgeNode> >::iterator iRidge;
    vector<RidgeNode>::iterator iNode;

    //create ridge straight line (weighted linear regression)
    for (iRidge = ridges.begin( ); iRidge != ridges.end( ); ++iRidge) {
        printf( "check one ridge with size=%d\n", iRidge->size( ) );

        if (iRidge->size( ) <= 1) {
            continue;
        }
        //units are still cells.
        //now we need to decide where to draw the points:
        //because there are extra fraction points, we may need to adjust
        //the points to the center of the segment.
        //For now, we go floor not ceiling.
        double startX = iRidge->front( ).x;
        double endX   = iRidge->back( ).x;
        //if (startX == 0) {
            //start from edge of matrix.
        //    startX = -0.5;
        //}
        //if (endX == double(m_numColumn - 1)) {
        //    endX += 0.5;
            //end at edge of matrix
        //}
        double centerX = (endX + startX) / 2.0;
        double lengthX =  endX - startX;
        double scale   = 0.0;
        double offset  = 0;
        int numPoints =
            int ((lengthX + beamSpace) / (beamWidth + beamSpace));
        double left = lengthX + beamSpace
            - numPoints * (beamWidth + beamSpace);
        printf( "startX = %lf endX=%lf numP=%d\n", startX, endX, numPoints );
        printf( "left=%lf\n", left );


        vector<double> x;
        vector<double> y;
        vector<double> w;
        for (iNode = iRidge->begin( ); iNode != iRidge->end( ); ++iNode) {
            if (iNode->w > 0) {
                x.push_back(iNode->x);
                y.push_back(iNode->y);
                w.push_back(iNode->w);
            }
        }
        printf( "valid weight points: %d\n", x.size( ) );
        if (x.size( ) == 1) {
            scale = 0;
            offset = y[0];
        } else {
            if (!myEngine.Regress( x, y, w, 1 )) {
                printf( "ERROR linear regression failed\n" );
                continue;
            }
            vector<double> coef = myEngine.getCoefficients( );
            offset = coef[0];
            scale  = coef[1];
        }

        //DEBUG
        for (iNode = iRidge->begin( ); iNode != iRidge->end( ); ++iNode) {
            double newY = offset + scale * iNode->x;
            printf( "adjust (%f %f)", iNode->x, iNode->y );
            printf( "->(%f %f)\n", iNode->x, newY );
        }
        //DEBUG

        iRidge->clear( );
        //start edge
        double newX = startX;
        double newY = offset + scale * newX;
        iRidge->push_back( RidgeNode( newX, newY, 0 ) );
        printf( "startint edge: %lf %lf\n", newX, newY );

        //data points
        if (numPoints < 2) {
            newX = centerX;
            newY = offset + scale * newX;
            iRidge->push_back( RidgeNode( newX, newY, 1 ) );
        } else {
            double firstX = startX + (left + beamWidth) / 2.0;
            printf( "first X=%lf\n", firstX );

            for (int i = 0; i < numPoints; ++i) {
                newX = firstX + i * (beamWidth + beamSpace);
                newY = offset + scale * newX;
                printf( "point[%d]= %lf %lf\n", i, newX, newY );
                iRidge->push_back( RidgeNode( newX, newY, i + 1 ) );
            }
        }

        //end edge
        newX = endX;
        newY = offset + scale * newX;
        iRidge->push_back( RidgeNode( newX, newY, 0 ) );
    }

    // convert to gui units.
    for (iRidge = ridges.begin( ); iRidge != ridges.end( ); ++iRidge) {
        for (iNode = iRidge->begin( ); iNode != iRidge->end( ); ++iNode) {
            iNode->x = (iNode->x + 0.5) * m_nodeWidth;
            iNode->y = (iNode->y + 0.5) * m_nodeHeight;
        }
    }
    return result;
}
int DcsMatrix::traceEdge(
    int& next_row, int& next_col, Direction& next_move,
    double x[], double y[], int& length, int maxLength
) const {

    static const EdgeScan left[5] =
    {EDGE_LEFT_TOP, EDGE_TOP, EDGE_RIGHT, EDGE_BOTTOM, EDGE_LEFT_BOTTOM};

    static const EdgeScan top[5] =
    {EDGE_TOP_RIGHT, EDGE_RIGHT, EDGE_BOTTOM, EDGE_LEFT, EDGE_TOP_LEFT};

    static const EdgeScan right[5] =
    {EDGE_RIGHT_BOTTOM, EDGE_BOTTOM, EDGE_LEFT, EDGE_TOP, EDGE_RIGHT_TOP};

    static const EdgeScan bottom[5] =
    {EDGE_BOTTOM_LEFT, EDGE_LEFT, EDGE_TOP, EDGE_RIGHT, EDGE_BOTTOM_RIGHT};


    printf( "traceEdge %d %d %d for %p\n", next_row, next_col, next_move, this );

    const EdgeScan *pStep = NULL;
    switch (next_move) {
        case LEFT:
            pStep = left;
            break;
        case RIGHT:
            pStep = right;
            break;
        case UP:
            pStep = top;
            break;
        case DOWN:
            pStep = bottom;
            break;
        default:
            return 0;
    }


    if (length >= maxLength) {
        printf( "array full\n" );
        return 0;
    }

    int row(next_row);
    int col(next_col);

    for (int step = 0; step < 5; ++step) {
        switch (pStep[step]) {
        case EDGE_LEFT:
            printf( "EDGE_LEFT\n" );
            x[length] = 0;
            y[length] = 0;
            ++length;
            if (length >= maxLength) {
                printf( "array full\n" );
                return 0;
            }

            col = 0;
            for (row = 0; row < m_numRow - 1; ++row) {
                if (VHit( row, col) == -1) {
                    next_row = row;
                    next_col = col;
                    next_move = RIGHT;
                    printf( "got %d %d\n", row, col );
                    return 1;
                }
            }
            break;

        case EDGE_TOP:
            printf( "EDGE_TOP\n" );
            x[length] = 0;
            y[length] = m_numRow - 1;
            ++length;
            if (length >= maxLength) {
                printf( "array full\n" );
                return 0;
            }

            row = m_numRow - 1;
            for (col = 0; col < m_numColumn - 1; ++col) {
                if (HHit( row, col ) == -1) {
                    next_row = row;
                    next_col = col;
                    next_move = DOWN;
                    printf( "got %d %d\n", row, col );
                    return 1;
                }
            }
            break;

        case EDGE_RIGHT:
            printf( "EDGE_RIGHT\n" );
            x[length] = m_numColumn - 1;
            y[length] = m_numRow - 1;
            ++length;
            if (length >= maxLength) {
                printf( "array full\n" );
                return 0;
            }
            col = m_numColumn - 1;
            for (row = m_numRow - 2; row >=0 ; --row) {
                if (VHit( row, col) == 1) {
                    next_row = row;
                    next_col = col;
                    next_move = LEFT;
                    printf( "got %d %d\n", row, col );
                    return 1;
                }
            }
            break;

        case EDGE_BOTTOM:
            printf( "EDGE_BOTTOM\n" );
            x[length] = m_numColumn - 1;
            y[length] = 0;
            ++length;
            if (length >= maxLength) {
                printf( "array full\n" );
                return 0;
            }

            row = 0;
            for (col = m_numColumn - 2; col >= 0; --col) {
                if (HHit( row, col ) == 1) {
                    next_row = row;
                    next_col = col;
                    next_move = UP;
                    printf( "got %d %d\n", row, col );
                    return 1;
                }
            }
            break;

        case EDGE_LEFT_TOP:
            printf( "EDGE_LEFT_TOP\n" );
            col = 0;
            for (row = next_row; row < m_numRow - 1; ++row) {
                if (VHit( row, col) == -1) {
                    next_row = row;
                    next_col = col;
                    next_move = RIGHT;
                    printf( "got %d %d\n", row, col );
                    return 1;
                }
            }
            break;

        case EDGE_LEFT_BOTTOM:
            printf( "EDGE_LEFT_BOTTOM\n" );
            x[length] = 0;
            y[length] = 0;
            ++length;
            if (length >= maxLength) {
                printf( "array full\n" );
                return 0;
            }

            col = 0;
            for (row = 0; row < next_row; ++row) {
                if (VHit( row, col) == -1) {
                    next_row = row;
                    next_col = col;
                    next_move = RIGHT;
                    printf( "got %d %d\n", row, col );
                    return 1;
                }
            }
            break;

        case EDGE_TOP_LEFT:
            printf( "EDGE_TOP_LEFT\n" );
            x[length] = 0;
            y[length] = m_numRow - 1;
            ++length;
            if (length >= maxLength) {
                printf( "array full\n" );
                return 0;
            }

            row = m_numRow - 1;
            for (col = 0; col < next_col; ++col) {
                if (HHit( row, col ) == -1) {
                    next_row = row;
                    next_col = col;
                    next_move = DOWN;
                    printf( "got %d %d\n", row, col );
                    return 1;
                }
            }
            break;

        case EDGE_TOP_RIGHT:
            printf( "EDGE_TOP_RIGHT\n" );
            row = m_numRow - 1;
            for (col = next_col; col < m_numColumn - 1; ++col) {
                if (HHit( row, col ) == -1) {
                    next_row = row;
                    next_col = col;
                    next_move = DOWN;
                    printf( "got %d %d\n", row, col );
                    return 1;
                }
            }
            break;

        case EDGE_RIGHT_TOP:
            printf( "EDGE_RIGHT_TOP\n" );
            x[length] = m_numColumn - 1;
            y[length] = m_numRow - 1;
            ++length;
            if (length >= maxLength) {
                printf( "array full\n" );
                return 0;
            }
            col = m_numColumn - 1;
            for (row = m_numRow - 2; row > next_row ; --row) {
                if (VHit( row, col) == 1) {
                    next_row = row;
                    next_col = col;
                    next_move = LEFT;
                    printf( "got %d %d\n", row, col );
                    return 1;
                }
            }
            break;

        case EDGE_RIGHT_BOTTOM:
            printf( "EDGE_RIGHT_BOTTOM\n" );
            col = m_numColumn - 1;
            for (row = next_row; row >=0 ; --row) {
                if (VHit( row, col) == 1) {
                    next_row = row;
                    next_col = col;
                    next_move = LEFT;
                    printf( "got %d %d\n", row, col );
                    return 1;
                }
            }
            break;

        case EDGE_BOTTOM_LEFT:
            printf( "EDGE_BOTTOM_LEFT\n" );
            row = 0;
            for (col = next_col; col >= 0; --col) {
                if (HHit( row, col ) == 1) {
                    next_row = row;
                    next_col = col;
                    next_move = UP;
                    printf( "got %d %d\n", row, col );
                    return 1;
                }
            }
            break;

        case EDGE_BOTTOM_RIGHT:
            printf( "EDGE_BOTTOM_RIGHT\n" );
            x[length] = m_numColumn - 1;
            y[length] = 0;
            ++length;
            if (length >= maxLength) {
                printf( "array full\n" );
                return 0;
            }

            row = 0;
            for (col = m_numColumn - 2; col > next_col; --col) {
                if (HHit( row, col ) == 1) {
                    next_row = row;
                    next_col = col;
                    next_move = UP;
                    printf( "got %d %d\n", row, col );
                    return 1;
                }
            }
            break;
        }
    }

    //should not be here.
    printf( "!!!!!!!!!!!!! SHOULD NOT BE HERE!!!!!!!!!!!!!\n" );
    return 0;
}
