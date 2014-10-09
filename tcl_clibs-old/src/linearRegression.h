#include <vector>

#ifndef ___LINEAR_REGRESSION_H___
#define ___LINEAR_REGRESSION_H___

using namespace std;

class LinearRegression {
public:
    const vector<double>& getCoefficients( ) const {
        return m_C;
    }
    double getMaxError( ) const {
        return m_maxError;
    }

    bool Regress(
        const vector<double> &Y,
        const vector<double> &X,
        const vector<double> &W,
        int   order
    );

private:
    bool SymmetricMatrixInvert( vector<vector<double> > & );

    double m_maxError;
    vector<double> m_C;      // Coefficients
    vector<double> m_SEC;    // Std Error of coefficients
    double m_RYSQ;            // Multiple correlation coefficient
    double m_SDV;             // Standard deviation of errors
    double m_FReg;            // Fisher F statistic for regression
    vector<double> m_Ycalc;         // Calculated values of Y
    vector<double> m_DY;            // Residual values of Y
};
#endif //___LINEAR_REGRESSION_H___
