

/*
 Authors 
 Martin Schlather, schlather@math.uni-mannheim.de


 Copyright (C) 2015 -- 2017 Martin Schlather

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.  
*/

#ifndef RFQMath_H
#define RFQMath_H 1


void MathCos(double *x, int *, model *cov, double *v);
void MathSin(double *x, int *, model *cov, double *v);
void MathTan(double *x, int *, model *cov, double *v);



#define MATH_FACTOR 2

#define CONST_C 0
#define CONST_NAME 1
void Mathminus(double *x, int *, model *cov, double *v);
void Mathplus(double *x, int *, model *cov, double *v);
void Mathmult(double *x, int *, model *cov, double *v);
void Mathdiv(double *x, int *, model *cov, double *v);
void Mathc(double *x, int *, model *cov, double *v);
void rangec(model *cov, int k, int i, int j, simple_range_type *range);
int check_c(model *cov);

void MathIs(double *x, int*, model *cov, double *v);
void rangeMathIs(model *cov, range_type *range);

#define BIND_VARIABLES 16
#define BIND_NCOL (BIND_VARIABLES + 0)
#define BIND_FACTOR (BIND_VARIABLES + 1)
void Mathbind(double *x, int *, model *cov, double *v);
int check_bind(model *cov);
bool setbind(model *cov);
bool allowedIbind(model *cov);
bool allowedDbind(model *cov);
Types Typebind(Types required, model *cov, isotropy_type i);

int checkDivMult(model *cov);


#define PROJ_PROJ 0
#define PROJ_ISO 1
#define PROJ_FACTOR 2
#define PROJ_NAME 3
void proj(double *x, int *, model *cov, double *v);
bool setproj(model *cov);
int checkproj(model *cov);
void rangeproj(model VARIABLE_IS_NOT_USED *cov, range_type *range);
Types Typeproj(Types required, model *cov, isotropy_type required_iso);
bool allowedIp(model *cov);


void kappa_math(int i, model *cov, int *nr, int *nc);
int checkMath(model *cov);
void rangeMath(model *cov, range_type *range);

#define MATH_DEFAULT_0(VARIAB)						\
  int i,								\
    variables = (VARIAB);						\
  double w[MAXPARAM];							\
  for (i=0; i<variables; i++) {						\
    model *sub = cov->kappasub[i];					\
    if (sub != NULL) {							\
      COV(x, info, sub, w + i);						\
    } else { w[i] = P0(i); }						\
  }									\
  // printf("sin %10g w=%10g;%10g %10g %d %d nr = %d %d\n", x[0], w[0], w[1], P0(1), variables, p[1], cov->nrow[0] > 0, cov->nrow[1] > 0);

#define MATH_DEFAULT MATH_DEFAULT_0(DefList[COVNR].kappas)



#endif
