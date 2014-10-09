#include "linearRegression.h"

#include <cstdio>
#include <math.h>

bool LinearRegression::Regress(
    const vector<double> &x,
    const vector<double> &Y,
    const vector<double> &W,
    int N 
) {
    size_t M = Y.size( );
    if (M > x.size( )) {
        M = x.size( );
    }
    if (M > W.size( )) {
        M = W.size( );
    }

    printf( "Regress data point =%d order=%d\n", M, N );
    for (size_t i = 0; i < M; ++i) {
        //printf( "data[%d] x=%f y=%f w=%f\n", i, x[i], Y[i], W[i] );
    }

    int NDF = M - N;
    if (N < 0 || NDF < 1) {
        printf( "not enough data" );
        return false;
    }

    // order 1 has 2 coeff ....
    N += 1;

    //prepare X (containts the poly x
    vector<vector<double> > X(N, vector<double>(M,1));
    for (int i = 0; i < M; ++i) {
        double xx = x[i];
        double term = xx;
        for (int j = 1; j < N; ++j) {
            X[j][i] = term;
            term *= xx;
        }
    }
    /* debug
    for (int i = 0; i < M; ++i) {
        printf( "X[%d]:", i );
        for (int j = 0; j < N; ++j) {
            printf( " %f", X[j][i] );
        }
        printf( "\n" );
    }
    */
    m_Ycalc.assign( M, 0 );
    m_DY.assign( M, 0 );

    vector<vector<double> > V( N, vector<double>( N, 0 ));
    m_C.assign( N, 0 );
    m_SEC.assign( N, 0 );

    vector<double> B;
    B.assign( N, 0 ); // Vector for LSQ

    // Form Least Squares Matrix
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            V[i][j] = 0;
            for (int k = 0; k < M; k++) {
                V[i][j] = V[i][j] + W[k] * X[i][k] * X[j][k];
            }
        }
        B[i] = 0;
        for (int k = 0; k < M; k++) {
            B[i] = B[i] + W[k] * X[i][k] * Y[k];
        }
    }
    // V now contains the raw least squares matrix
    if (!SymmetricMatrixInvert(V)) {
        return false;
    }
    // V now contains the inverted least square matrix
    // Matrix multpily to get coefficients m_C = VB
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            m_C[i] = m_C[i] + V[i][j] * B[j];
        }
    }

    // Calculate statistics
    double TSS = 0;
    double RSS = 0;
    double YBAR = 0;
    double WSUM = 0;
    for (int k = 0; k < M; k++) {
        YBAR = YBAR + W[k] * Y[k];
        WSUM = WSUM + W[k];
    }
    YBAR = YBAR / WSUM;
    for (int k = 0; k < M; k++) {
        m_Ycalc[k] = 0;
        for (int i = 0; i < N; i++) {
            m_Ycalc[k] = m_Ycalc[k] + m_C[i] * X[i][k];
        }
        m_DY[k] = m_Ycalc[k] - Y[k];
        TSS = TSS + W[k] * (Y[k] - YBAR) * (Y[k] - YBAR);
        RSS = RSS + W[k] * m_DY[k] * m_DY[k];
    }
    double SSQ = RSS / NDF;
    m_RYSQ = 1 - RSS / TSS;
    m_FReg = 9999999;
    if (m_RYSQ < 0.9999999) {
        m_FReg = m_RYSQ / (1 - m_RYSQ) * NDF / (N - 1);
    }
    double SDV = sqrt(SSQ);

    // Calculate var-covar matrix and std error of coefficients
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            V[i][j] = V[i][j] * SSQ;
        }
        m_SEC[i] = sqrt(V[i][i]);
    }

    m_maxError = 0;
    for (int i = 0; i < M; ++i) {
        double dd = fabs( m_DY[i] );
        if (dd > m_maxError) {
            m_maxError = dd;
        }
    }
    return true;
}

bool LinearRegression::SymmetricMatrixInvert( vector<vector<double> > &V ) {
    int N = (int)V.size( );

    /* debug
    printf( "invert matrix N=%d\n", N );
    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j) {
            printf( "%9.3lf ", V[i][j] );
        }
        printf( "\n" );
    }
    */

    vector<double> t( N, 0 );
    vector<double> Q( N, 0 );
    vector<double> R( N, 1 );
    double AB;
    int K = 0;
    int L;
    int M;

    // Invert a symetric matrix in V
    for (M = 0; M < N; M++) {
        double Big = 0;
        for (L = 0; L < N; L++) {
            AB = fabs(V[L][L]);
            //printf( "big=%f AB=%f for[%d]\n", Big, AB, L );
            //printf( "R[%d]=%f\n", L, R[L] );
            if ((AB > Big) && (R[L] != 0)) {
                Big = AB;
                K = L;
                //printf( "new Big=%f K=%d\n", Big, K );
            }
        }
        if (Big == 0) {
            printf( "failed big == 0 for M=%d\n", M );
            return false;
        }
        R[K] = 0;
        Q[K] = 1 / V[K][K];
        t[K] = 1;
        V[K][K] = 0;
        if (K != 0) {
            for (L = 0; L < K; L++) {
                t[L] = V[L][K];
                if (R[L] == 0) {
                    Q[L] = V[L][K] * Q[K];
                } else {
                    Q[L] = -V[L][K] * Q[K];
                }
                V[L][K] = 0;
            }
        }
        if ((K + 1) < N) {
            for (L = K + 1; L < N; L++) {
                if (R[L] != 0) {
                    t[L] = V[K][L];
                } else {
                    t[L] = -V[K][L];
                }
                Q[L] = -V[K][L] * Q[K];
                V[K][L] = 0;
            }
        }
        for (L = 0; L < N; L++) {
            for (K = L; K < N; K++) {
                V[L][K] = V[L][K] + t[L] * Q[K];
            }
        }
    }
    M = N;
    L = N - 1;
    for (K = 1; K < N; K++) {
        M = M - 1;
        L = L - 1;
        for (int J = 0; J <= L; J++) {
            V[M][J] = V[J][M];
        }
    }
    return true;
}
