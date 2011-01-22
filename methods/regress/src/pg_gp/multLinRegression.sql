/* ----------------------------------------------------------------------- *//** 
 *
 * @file multLinRegression.sql
 *
 * @brief SQL functions for multi-linear and logistic regression
 * @date   January 2011
 *
 *//* ----------------------------------------------------------------------- */
 
/**
@addtogroup grp_linreg

@about

Linear regression refers to a stochastic model, in which the conditional mean
of the dependent variable (usually denoted $y$) is an affine function of the
independent variables (usually denoted \f$ \boldsymbol x \f$).

@prereq

Implemented in C for PostgreSQL/Greenplum.

@usage

-# The data set is expected to be of the following form:\n
   <tt>{TABLE|VIEW} <em>sourceName</em> ([...] <em>dependentVariable</em>
   DOUBLE PRECISION, <em>independentVariables</em> DOUBLE PRECISION[],
   [...])</tt>  
-# Run the linear regression by:\n
   <tt>SELECT mregr_coef('<em>sourceName</em>', '<em>dependentVariable</em>',
   '<em>independentVariables</em>')</tt>\n
-# The coefficient of determination (also denoted $R^2$), the vector of t-statistics, and the
   vector of p-values can be determined likewise by mregr_r2(), mregr_tstats(),
   mregr_pvalues().

@examp

The following examples is taken from
http://www.stat.columbia.edu/~martin/W2110/SAS_7.pdf.

@verbatim
# select * from houses;
 id | tax  | bedroom | bath | price  | size |  lot  
----+------+---------+------+--------+------+-------
  1 |  590 |       2 |    1 |  50000 |  770 | 22100
  2 | 1050 |       3 |    2 |  85000 | 1410 | 12000
  3 |   20 |       3 |    1 |  22500 | 1060 |  3500
  4 |  870 |       2 |    2 |  90000 | 1300 | 17500
  5 | 1320 |       3 |    2 | 133000 | 1500 | 30000
  6 | 1350 |       2 |    1 |  90500 |  820 | 25700
  7 | 2790 |       3 |  2.5 | 260000 | 2130 | 25000
  8 |  680 |       2 |    1 | 142500 | 1170 | 22000
  9 | 1840 |       3 |    2 | 160000 | 1500 | 19000
 10 | 3680 |       4 |    2 | 240000 | 2790 | 20000
 11 | 1660 |       3 |    1 |  87000 | 1030 | 17500
 12 | 1620 |       3 |    2 | 118600 | 1250 | 20000
 13 | 3100 |       3 |    2 | 140000 | 1760 | 38000
 14 | 2070 |       2 |    3 | 148000 | 1550 | 14000
 15 |  650 |       3 |  1.5 |  65000 | 1450 | 12000
(15 rows)

# select mregr_coef(price, array[1, bedroom, bath, size])::REAL[] from houses;
             mregr_coef             
------------------------------------
 {27923.4,-35524.8,2269.34,130.794}
(1 row)

# select mregr_r2(price, array[1, bedroom, bath, size])::REAL from houses;
 mregr_r2 
----------
 0.745374
(1 row)

# select mregr_tstats(price, array[1, bedroom, bath, size])::REAL[] from houses;
             mregr_tstats             
--------------------------------------
 {0.495919,-1.41891,0.102183,3.61223}
(1 row)

# select mregr_pvalues(price, array[1, bedroom, bath, size])::REAL[] from houses;
              mregr_pvalues              
-----------------------------------------
 {0.629711,0.183633,0.920451,0.00408159}
(1 row)
@endverbatim

@sa file regress.c (documenting the implementation in C), function
	float8_mregr_compute() (documenting the formulas used for coefficients,
	$R^2$, t-statistics, and p-values, implemented in C)

@literature

[1] Cosma Shalizi: Statistics 36-350: Data Mining, Lecture Notes, 21 October
    2009, http://www.stat.cmu.edu/~cshalizi/350/lectures/17/lecture-17.pdf

*/

CREATE FUNCTION madlib.float8_mregr_accum(state DOUBLE PRECISION[], y DOUBLE PRECISION, x DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'multLinRegression'
LANGUAGE C
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION madlib.float8_mregr_combine(state1 DOUBLE PRECISION[], state2 DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'multLinRegression'
LANGUAGE C
IMMUTABLE STRICT;

--! Final functions
CREATE FUNCTION madlib.float8_mregr_coef(DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'multLinRegression'
LANGUAGE C STRICT;

CREATE FUNCTION madlib.float8_mregr_r2(DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION
AS 'multLinRegression'
LANGUAGE C STRICT;

CREATE FUNCTION madlib.float8_mregr_tstats(DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'multLinRegression'
LANGUAGE C STRICT;

CREATE FUNCTION madlib.float8_mregr_pvalues(DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'multLinRegression'
LANGUAGE C STRICT;

-- No warning message while creating aggregates. (PREFUNC is a Greenplum-only
-- attribute)
SET client_min_messages = error;

/**
 * @brief Compute multi-linear regression coefficients.
 */
CREATE AGGREGATE madlib.mregr_coef(DOUBLE PRECISION, DOUBLE PRECISION[]) (
	SFUNC=madlib.float8_mregr_accum,
	STYPE=float8[],
	FINALFUNC=madlib.float8_mregr_coef,
	PREFUNC=madlib.float8_mregr_combine,
	INITCOND='{0}'
);

/**
 * @brief Compute the coefficient of determination, $R^2$.
 */
CREATE AGGREGATE madlib.mregr_r2(DOUBLE PRECISION, DOUBLE PRECISION[]) (
	SFUNC=madlib.float8_mregr_accum,
	STYPE=float8[],
	FINALFUNC=madlib.float8_mregr_r2,
	PREFUNC=madlib.float8_mregr_combine,
	INITCOND='{0}'
);

/**
 * @brief Compute the vector of t-statistics, for every coefficient.
 */
CREATE AGGREGATE madlib.mregr_tstats(DOUBLE PRECISION, DOUBLE PRECISION[]) (
	SFUNC=madlib.float8_mregr_accum,
	STYPE=float8[],
	FINALFUNC=madlib.float8_mregr_tstats,
	PREFUNC=madlib.float8_mregr_combine,
	INITCOND='{0}'
);

/**
 * @brief Compute the vector of p-values, for every coefficient.
 */
CREATE AGGREGATE madlib.mregr_pvalues(DOUBLE PRECISION, DOUBLE PRECISION[]) (
	SFUNC=madlib.float8_mregr_accum,
	STYPE=float8[],
	FINALFUNC=madlib.float8_mregr_pvalues,
	PREFUNC=madlib.float8_mregr_combine,
	INITCOND='{0}'
);

RESET client_min_messages;

CREATE FUNCTION madlib.student_t_cdf(INTEGER, DOUBLE PRECISION)
RETURNS DOUBLE PRECISION
AS 'multLinRegression'
LANGUAGE C
IMMUTABLE STRICT;

CREATE TYPE madlib.logregr_cg_state AS (
	iteration		INTEGER,
	len				INTEGER,
	coef			DOUBLE PRECISION[],
	dir				DOUBLE PRECISION[],
	grad			DOUBLE PRECISION[],
	beta			DOUBLE PRECISION,

	count			BIGINT,
	gradNew			DOUBLE PRECISION[],
	dTHd			DOUBLE PRECISION,
	logLikelihood	DOUBLE PRECISION
);

CREATE TYPE madlib.logregr_irls_state AS (
	coef			DOUBLE PRECISION[],
	logLikelihood	DOUBLE PRECISION
);

CREATE FUNCTION madlib.float8_cg_update_accum(
	madlib.logregr_cg_state,
	BOOLEAN,
	DOUBLE PRECISION[],
	madlib.logregr_cg_state)
RETURNS madlib.logregr_cg_state
AS 'multLinRegression'
LANGUAGE C;

CREATE FUNCTION madlib.float8_irls_update_accum(
	DOUBLE PRECISION[],
	BOOLEAN,
	DOUBLE PRECISION[],
	madlib.logregr_irls_state)
RETURNS DOUBLE PRECISION[]
AS 'multLinRegression'
LANGUAGE C;

CREATE FUNCTION madlib.float8_cg_update_final(madlib.logregr_cg_state)
RETURNS madlib.logregr_cg_state
AS 'multLinRegression'
LANGUAGE C STRICT;

CREATE FUNCTION madlib.float8_irls_update_final(DOUBLE PRECISION[])
RETURNS madlib.logregr_irls_state
AS 'multLinRegression'
LANGUAGE C STRICT;

CREATE AGGREGATE madlib.logreg_cg_step(BOOLEAN, DOUBLE PRECISION[], madlib.logregr_cg_state) (
	SFUNC=madlib.float8_cg_update_accum,
	STYPE=madlib.logregr_cg_state,
	FINALFUNC=madlib.float8_cg_update_final
);

CREATE AGGREGATE madlib.logreg_irls_step(BOOLEAN, DOUBLE PRECISION[], madlib.logregr_irls_state) (
	SFUNC=madlib.float8_irls_update_accum,
	STYPE=float8[],
	PREFUNC=madlib.float8_mregr_combine,
	FINALFUNC=madlib.float8_irls_update_final,
	INITCOND='{0}'
);

CREATE FUNCTION madlib.logreg_should_terminate(
	DOUBLE PRECISION[],
	DOUBLE PRECISION[],
	VARCHAR,
	DOUBLE PRECISION)
RETURNS BOOLEAN
AS 'multLinRegression'
LANGUAGE C STRICT;

CREATE FUNCTION madlib.logregr_coef(
	"source" VARCHAR,
	"depColumn" VARCHAR,
	"indepColumn" VARCHAR)
RETURNS DOUBLE PRECISION[] AS $$
	import logRegress
	return logRegress.compute_logreg_coef(**globals())
$$ LANGUAGE plpythonu VOLATILE;


CREATE FUNCTION madlib.logregr_coef(
	"source" VARCHAR,
	"depColumn" VARCHAR,
	"indepColumn" VARCHAR,
	"numIterations" INTEGER)
RETURNS DOUBLE PRECISION[] AS $$
	import logRegress
	return logRegress.compute_logreg_coef(**globals())
$$ LANGUAGE plpythonu VOLATILE;


CREATE FUNCTION madlib.logregr_coef(
	"source" VARCHAR,
	"depColumn" VARCHAR,
	"indepColumn" VARCHAR,
	"numIterations" INTEGER,
	"optimizer" VARCHAR)
RETURNS DOUBLE PRECISION[] AS $$
	import logRegress
	return logRegress.compute_logreg_coef(**globals())
$$ LANGUAGE plpythonu VOLATILE;


--! Logistic regression
--! 
--! @param source Name of the source relation containing the training data
--! @param depColumn Name of the dependent column (of type BOOLEAN)
--! @param indepColumn Name of the independent column (of type DOUBLE
--!		PRECISION[])
--! @param numIterations The maximum number of iterations
--! @param optimizer The optimizer to use (either
--!		<tt>'ilrs'</tt>/<tt>'newton'</tt> for iteratively reweighted least
--!		squares or <tt>'cg'</tt> for conjugent gradient)
--! @param precision The difference between log-likelihood values in successive
--!		iterations that should indicate convergence, or 0 indicating that
--!		log-likelihood values should be ignored
CREATE FUNCTION madlib.logreg_coef(
	"source" VARCHAR,
	"depColumn" VARCHAR,
	"indepColumn" VARCHAR,
	"numIterations" INTEGER,
	"optimizer" VARCHAR,
	"precision" DOUBLE PRECISION)
RETURNS DOUBLE PRECISION[] AS $$
	import logRegress
	return logRegress.compute_logreg_coef(**globals())
$$ LANGUAGE plpythonu VOLATILE;


CREATE FUNCTION madlib.init_python_paths()
RETURNS VOID AS
$$
	# FIXME: The following code should of course not reside in a specialized
	# module such as regression.sql
	import sys

	dyld_paths = plpy.execute(
		"SHOW dynamic_library_path")[0]["dynamic_library_path"].split(':')
	before_default = True
	count = 0
	for path in dyld_paths:
		if path == "$libdir":
			before_default = False
		else:
			if before_default:
				sys.path.insert(count, path)
				count += 1
			else:
				sys.path.append(path)
$$ LANGUAGE plpythonu VOLATILE;
