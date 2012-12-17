#include <stdio.h>
#include <float.h>
#include "matrix.h"

DcsMatrix::DcsMatrix( ): m_numRow(0)
, m_numColumn(0)
, m_pData(NULL)
, m_pValidValue(NULL)
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
    //check input
    if (numRow < 2 || numColumn < 2) {
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

//return
// 1:  OK, max min not changed
// 0:  failed
// -1: OK, max min changed

int DcsMatrix::putValue( int row, int column, double value )
{
    //check input range
    if (row < 0 || row >= m_numRow || column < 0 || column >= m_numColumn)
    {
        printf( "DcsMatrix::putValue: bad row %d or column %d\n", row, column );
        printf( "numrow %d numcolumn %d\n", m_numRow, m_numColumn );
        return 0;
    }

    //check state: whether that position already has value
    int data_index = toDataIndex( row, column );
    //printf( "DEBUG: data_index=%d\n", data_index );
    if (m_pValidValue[data_index])
    {
        printf( "DcsMatrix::putValue: (%d,%d) already has value %lf, %lf ignored\n",
                 row, column, m_pData[data_index], value );
        return 0;
    }

    //OK, save the value
    m_pData[data_index] = value;
    m_pValidValue[data_index] = 1;

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

int DcsMatrix::getValue( int row, int column, double& value ) const
{
    //check input range
    if (row < 0 || row >= m_numRow || column < 0 || column >= m_numColumn)
    {
        printf( "DcsMatrix::getValue: bad row %d or column %d\n", row, column );
        return 0;
    }
    //check state: whether that position already has value
    int data_index = toDataIndex( row, column );
    if (!m_pValidValue[data_index])
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
        if (!find_next_move( row, col, next_move))
        {
            printf( "no more move" );
            return;
        }
        switch (next_move)
        {
        case LEFT:
        case RIGHT:
            //clear flag
            m_pVHitTable[toVHitIndex( row, col )] = 0;
            //calculate
            getCrossVertPosition( row, col, level, current_x, current_y );
            break;

        case UP:
        case DOWN:
            //clear flag
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
            if (HHit( row, col ))
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
            if (VHit( row, col ))
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

DcsScan2DData::DcsScan2DData( ): m_inited(false)
, m_firstRowY(0)
, m_lastRowY(0)
, m_firstColumnX(0)
, m_lastColumnX(0)
, m_nodeWidth(1)
, m_nodeHeight(1)
, m_rowPlotHeight(100)
, m_columnPlotWidth(100)
, m_maxColor(255)
, m_rowScale(0)
, m_columnScale(0)
, m_colorScale(0)
, m_rowPlotScale(0)
, m_columnPlotScale(0)
{
}

int DcsScan2DData::setup( int numRow, double firstRowY, double lastRowY, int numColumn, double firstColumnX, double lastColumnX, int maxColor )
{
    m_inited = false;
    m_colorScale = 0;
    //call base class setup first to check numRow and numColumn
    if (!DcsMatrix::setup( numRow, numColumn ))
    {
        return 0;
    }

    //check other inputs
    if (firstRowY == lastRowY || firstColumnX == lastColumnX)
    {
        printf( "bad first last value\n" );
        return 0;
    }
    if (maxColor < 1)
    {
        printf( "bad max color value\n" );
        return 0;
    }

    //save data
    m_firstRowY = firstRowY;
    m_lastRowY = lastRowY;
    m_firstColumnX = firstColumnX;
    m_lastColumnX = lastColumnX;
    m_maxColor = maxColor;

    //calculate scale for row and column to make convenient for x->column and y->row
    m_rowScale = (m_numRow - 1) / (m_lastRowY - m_firstRowY);
    m_columnScale = (m_numColumn - 1) / (m_lastColumnX - m_firstColumnX);

    m_inited = true;
    return 1;
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

    int row = int( y / m_nodeWidth );
    int col = int( x / m_nodeHeight );

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
