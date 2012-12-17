#ifndef DCS_MATRIX
#include <memory.h>
#include <stdio.h>

class DcsContourSegment {
public:
    DcsContourSegment( ): m_offset(0), m_length(0) { }
    int m_offset;
    int m_length;
};

class DcsMatrix {
public:
    DcsMatrix( );
    virtual ~DcsMatrix( );

    //set up.  This will also clear the matrix
    int setup( int numRow, int numColumn );
    int putValue( int row, int column, double value );

    void setAllUndefinedNodeToMin( );

    //retrieve info
    int getNumRow( ) const { return m_numRow; }
    int getNumColumn( ) const { return m_numColumn; }
    int getValue( int row, int column, double& value ) const;
    void getRow( int row, int maxLength, double value[], int& length ) const;
    void getColumn( int column, int maxLength, double value[], int& length ) const;
    int getContour( double relative_level, int maxLength, double x[], double y[], int& length, int maxSegment, DcsContourSegment segments[] ) const;

    int allDataDefined( ) const;

    //DEBUG
    void printHitTable( ) const;
    
private:
    enum Direction { LEFT, UP, RIGHT, DOWN };

    inline void getNeighbor( Direction move,
             int current_row, int current_col,
             int& left_col, int& right_col, int& top_row, int& bottom_row) const
    {
        switch (move)
        {
        case LEFT:
            left_col = current_col - 1;
            right_col = current_col;
            top_row = current_row + 1;
            bottom_row = current_row;
            break;

        case RIGHT:
            left_col = current_col;
            right_col = current_col + 1;
            top_row = current_row + 1;
            bottom_row = current_row;
            break;

        case UP:
            left_col = current_col;
            right_col = current_col + 1;
            top_row = current_row + 1;
            bottom_row = current_row;
            break;

        case DOWN:
            left_col = current_col;
            right_col = current_col + 1;
            top_row = current_row;
            bottom_row = current_row - 1;
            break;

        }
    }
    inline int toDataIndex( int row, int column) const
    {
        return row * m_numColumn + column;
    }
    inline int toHHitIndex( int row, int column ) const
    {
        //return row * (m_numColumn - 1) + column - 1;
        return row * (m_numColumn - 1) + column;
    }
    inline int toVHitIndex( int row, int column ) const
    {
        //return (row - 1) * m_numColumn + column;
        return row * m_numColumn + column;
    }

    inline signed char HHit( int row, int column ) const
    {
        return m_pHHitTable[toHHitIndex( row, column )];
    }
    
    inline signed char VHit( int row, int column ) const
    {
        return m_pVHitTable[toVHitIndex( row, column )];
    }

    inline void getCrossHorzPosition( int row, int column, double level,
                    double& x, double& y ) const
    {
        int current_index = toDataIndex( row, column );
        int other_index = toDataIndex( row, column + 1 );

        x = column + 1.0 / (m_pData[other_index] - m_pData[current_index])
                         * (level - m_pData[current_index]);
        y = row;

        if (x < 0.0 || y < 0.0)
        {
            printf( "getHorzP: (%d, %d)\n", row, column );
            printf( "index %d, %d\n", current_index, other_index );
            printf( "value %lf, %lf\n", m_pData[current_index], m_pData[other_index]);
            printf( "x=%lf, y=%lf\n", x, y );
        }
    }
    
    inline void getCrossVertPosition( int row, int column, double level,
                    double& x, double& y ) const
    {
        int current_index = toDataIndex( row, column );
        int other_index = toDataIndex( row + 1, column );

        x = column;
        y = row + 1.0 / (m_pData[other_index] - m_pData[current_index])
                         * (level - m_pData[current_index]);
        if (x < 0.0 || y < 0.0)
        {
            printf( "getVertP: (%d, %d)\n", row, column );
            printf( "index %d, %d\n", current_index, other_index );
            printf( "value %lf, %lf\n", m_pData[current_index], m_pData[other_index]);
            printf( "x=%lf, y=%lf\n", x, y );
        }
    }
    
    void findHit( double level ) const;
    int find_next_move( int& next_row, int& next_col, Direction& next_move ) const;
    void find_segment( double level, int maxLength, bool startVertical, int startRow, int startCol, double x[], double y[], int& length ) const;
    
protected:
    int m_numRow;
    int m_numColumn;
    double m_valueMin;
    double m_valueMax;

private:
    double* m_pData;
    char* m_pValidValue;
    size_t m_DataSize;

    signed char* m_pVHitTable;
    size_t m_VHitSize;
    signed char* m_pHHitTable;
    size_t m_HHitSize;
};

class DcsScan2DData: public DcsMatrix
{
public:
    DcsScan2DData( );
    virtual ~DcsScan2DData( ) { }
    
    int setup( int numRow, double firstRowY, double LastRowY, int numColumn, double firstColumnX, double lastColumnX, int maxColor = 255 );
    int addData( double x, double y, double value );

    inline int getMinMax( double& min, double& max ) const
    {
        if (!m_inited) return 0;

        min = m_valueMin;
        max = m_valueMax;

        return 1;   
    }

    int toColumnRow( double x, double y, int& column, int& row ) const;

    //how to convert x, y to pixel units
    void setNodeSize( double width, double height )
    {
        m_nodeWidth = width;
        m_nodeHeight = height;
    }

    void setRowColumnPlotSize( double rowPlotHeight, double columnPlotWidth )
    {
        m_rowPlotHeight = rowPlotHeight;
        m_columnPlotWidth = columnPlotWidth;
    }

    int getColor( int row, int col ) const;

    int getValue( double x, double y, double& value ) const;

    void getRowPlot( double y0, int maxLength, double x[], double y[], int& length ) const;
    void getColumnPlot( double x0, int maxLength, double x[], double y[], int& length ) const;
    
    int getContour( double relative_level, int maxLength, double x[], double y[], int& length, int maxSegment, DcsContourSegment segments[] ) const;

private:
    inline int toRow( double y ) const
    {
        return int((y - m_firstRowY) * m_rowScale + 0.5);
    }
    inline int toColumn( double x ) const
    {
        return int((x - m_firstColumnX) * m_columnScale + 0.5);
    }

    ////////////////////////////STATIC function//////////////
public:
    enum AxisStepStyle
    {
        STEP_1 = 1,
        STEP_2 = 2,
        STEP_5 = 5,
    };
    static int generateAxis( double start, double end,
                     double& step_size, int& n_start, int& num_marks,
                     AxisStepStyle& step_style );
    
private:
    bool   m_inited;
    double m_firstRowY;
    double m_lastRowY;
    double m_firstColumnX;
    double m_lastColumnX;
    int    m_maxColor;
    double m_nodeWidth;
    double m_nodeHeight;
    double m_rowPlotHeight;
    double m_columnPlotWidth;

    double m_rowScale;
    double m_columnScale;
    mutable double m_colorScale; //calculate from m_valueMin, m_valueMax and m_maxColor
    mutable double m_rowPlotScale; //calculate from m_valueMin, m_valueMax and m_rowPlotHeight
    mutable double m_columnPlotScale; //calculate from m_valueMin, m_valueMax and m_columnPlotWidth
};

#define DCS_MATRIX
#endif //DCS_MATRIX
